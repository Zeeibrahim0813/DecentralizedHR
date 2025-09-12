import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

describe("Career Progression Integration Tests", () => {
  it("contract is deployed and accessible", () => {
    expect(simnet.blockHeight).toBeDefined();
    
    // Test that we can call a simple read-only function
    const { result } = simnet.callReadOnlyFn(
      "career-progression",
      "get-mentor-availability",
      [Cl.stringAscii("programming")],
      address1
    );
    
    // The function returns Ok with data - this means it worked
    // Type 7 = OK with tuple response
    expect(result.type).toBe(7);
  });

  it("can set and retrieve career goals", () => {
    // Set career goals
    const setResult = simnet.callPublicFn(
      "career-progression",
      "set-career-goals",
      [
        Cl.list([Cl.stringAscii("Senior Developer")]),
        Cl.list([Cl.stringAscii("Technology")]),
        Cl.uint(100000),
        Cl.uint(18),
        Cl.bool(true),
        Cl.bool(false)
      ],
      address1
    );
    
    expect(setResult.result).toBeOk(Cl.bool(true));
    
    // Get career goals
    const getResult = simnet.callReadOnlyFn(
      "career-progression",
      "get-employee-career-goals",
      [Cl.principal(address1)],
      address1
    );
    
    // The function returns Some with employee data - this means it worked
    // Type 10 = Some with data
    expect(getResult.result.type).toBe(10);
  });

  it("can register as mentor", () => {
    const { result } = simnet.callPublicFn(
      "career-progression",
      "register-mentor",
      [
        Cl.list([Cl.stringAscii("Leadership"), Cl.stringAscii("Technology")]),
        Cl.stringAscii("Senior Manager"),
        Cl.uint(8),
        Cl.uint(3)
      ],
      address2
    );
    
    expect(result).toBeOk(Cl.bool(true));
  });

  it("can create career path template", () => {
    const { result } = simnet.callPublicFn(
      "career-progression",
      "create-career-path",
      [
        Cl.stringAscii("Developer to Lead"),
        Cl.stringAscii("Technology"),
        Cl.stringAscii("Developer"),
        Cl.stringAscii("Tech Lead"),
        Cl.uint(5),
        Cl.list([Cl.stringAscii("leadership"), Cl.stringAscii("mentoring")]),
        Cl.uint(25000)
      ],
      address1
    );
    
    expect(result).toBeOk(Cl.bool(true));
  });

  it("can create skill development plan", () => {
    const { result } = simnet.callPublicFn(
      "career-progression",
      "create-skill-development-plan",
      [
        Cl.stringAscii("leadership"),
        Cl.uint(2),
        Cl.uint(4),
        Cl.list([Cl.stringAscii("Leadership Course")]),
        Cl.uint(12)
      ],
      address1
    );
    
    expect(result).toBeOk(Cl.bool(true));
  });

  it("generates recommendations after setting goals", () => {
    // First ensure goals are set
    simnet.callPublicFn(
      "career-progression",
      "set-career-goals",
      [
        Cl.list([Cl.stringAscii("Engineering Manager")]),
        Cl.list([Cl.stringAscii("Technology")]),
        Cl.uint(150000),
        Cl.uint(24),
        Cl.bool(true),
        Cl.bool(true)
      ],
      address1
    );

    // Generate recommendations
    const { result } = simnet.callPublicFn(
      "career-progression",
      "generate-recommendations",
      [Cl.principal(address1)],
      address1
    );
    
    expect(result).toBeOk(Cl.bool(true));
  });

  it("fails to generate recommendations without goals", () => {
    // Try to generate recommendations for address2 who hasn't set goals
    const { result } = simnet.callPublicFn(
      "career-progression",
      "generate-recommendations",
      [Cl.principal(address2)],
      address2
    );
    
    expect(result).toBeErr(Cl.uint(201)); // err-not-found
  });

  it("mentor registration fails with insufficient experience", () => {
    const { result } = simnet.callPublicFn(
      "career-progression",
      "register-mentor",
      [
        Cl.list([Cl.stringAscii("Programming")]),
        Cl.stringAscii("Junior Developer"),
        Cl.uint(2), // insufficient experience
        Cl.uint(1)
      ],
      address1
    );
    
    expect(result).toBeErr(Cl.uint(204)); // err-insufficient-experience
  });
});

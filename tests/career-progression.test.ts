import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const address3 = accounts.get("wallet_3")!;

describe("Career Progression Contract Tests", () => {
  it("ensures simnet is initialized", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  describe("Career Goals", () => {
    it("allows employee to set career goals", () => {
      const targetRoles = ["Senior Developer", "Tech Lead"];
      const preferredIndustries = ["Technology", "Finance"];
      const salaryTarget = 120000;
      const timelineMonths = 24;
      
      const { result } = simnet.callPublicFn(
        "career-progression",
        "set-career-goals",
        [
          Cl.list([Cl.stringAscii(targetRoles[0]), Cl.stringAscii(targetRoles[1])]),
          Cl.list([Cl.stringAscii(preferredIndustries[0]), Cl.stringAscii(preferredIndustries[1])]),
          Cl.uint(salaryTarget),
          Cl.uint(timelineMonths),
          Cl.bool(true), // location-flexibility
          Cl.bool(false) // remote-preference
        ],
        address1
      );
      
      expect(result).toBeOk(true);
    });

    it("retrieves employee career goals", () => {
      // First set goals
      simnet.callPublicFn(
        "career-progression",
        "set-career-goals",
        [
          ["Senior Developer"],
          ["Technology"],
          100000,
          18,
          true,
          true
        ],
        address1
      );

      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-employee-career-goals",
        [address1],
        address1
      );

      expect(result).toBeSome();
      if (result.type === "some") {
        expect(result.value).toHaveTupleKey("salary-target");
        expect(result.value["salary-target"]).toBeUint(100000);
      }
    });

    it("fails with invalid data", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "set-career-goals",
        [
          [], // empty target roles - should fail
          ["Technology"],
          100000,
          12,
          true,
          false
        ],
        address1
      );

      expect(result).toBeErr(203); // err-invalid-data
    });
  });

  describe("Mentor Registration", () => {
    it("allows user to register as mentor", () => {
      const expertiseAreas = ["Software Development", "Leadership", "Career Coaching"];
      
      const { result } = simnet.callPublicFn(
        "career-progression",
        "register-mentor",
        [
          expertiseAreas,
          "Senior Engineering Manager",
          8, // years experience
          3  // mentorship capacity
        ],
        address2
      );

      expect(result).toBeOk(true);
    });

    it("retrieves mentor profile", () => {
      // First register mentor
      simnet.callPublicFn(
        "career-progression",
        "register-mentor",
        [
          ["Leadership", "Tech Strategy"],
          "CTO",
          12,
          5
        ],
        address2
      );

      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-mentor-profile",
        [address2],
        address1
      );

      expect(result).toBeSome();
      if (result.type === "some") {
        expect(result.value).toHaveTupleKey("years-experience");
        expect(result.value["years-experience"]).toBeUint(12);
        expect(result.value["available"]).toBeBool(true);
      }
    });

    it("fails with insufficient experience", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "register-mentor",
        [
          ["Programming"],
          "Junior Developer",
          2, // insufficient experience
          1
        ],
        address3
      );

      expect(result).toBeErr(204); // err-insufficient-experience
    });
  });

  describe("Career Path Templates", () => {
    it("creates career path template", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "create-career-path",
        [
          "Developer to Tech Lead",
          "Technology",
          "Software Developer",
          "Technical Lead",
          5, // min years experience
          ["leadership", "architecture", "mentoring"],
          25000 // avg salary increase
        ],
        address2
      );

      expect(result).toBeOk(true);
    });

    it("retrieves career path template", () => {
      // First create a path
      simnet.callPublicFn(
        "career-progression",
        "create-career-path",
        [
          "Data Analyst to Data Scientist",
          "Data Science",
          "Data Analyst",
          "Data Scientist",
          3,
          ["machine-learning", "statistics", "python"],
          20000
        ],
        address2
      );

      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-career-path-template",
        [1], // path-id
        address1
      );

      expect(result).toBeSome();
      if (result.type === "some") {
        expect(result.value).toHaveTupleKey("path-name");
        expect(result.value).toHaveTupleKey("success-rate");
        expect(result.value["success-rate"]).toBeUint(75);
      }
    });
  });

  describe("Skill Development Plans", () => {
    it("creates skill development plan", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "create-skill-development-plan",
        [
          "leadership",
          2, // current level
          4, // target level
          ["Leadership Course", "Management Training", "Mentorship Program"],
          12 // estimated duration in months
        ],
        address1
      );

      expect(result).toBeOk(true);
    });

    it("updates skill progress", () => {
      // First create a plan
      simnet.callPublicFn(
        "career-progression",
        "create-skill-development-plan",
        [
          "project-management",
          1,
          3,
          ["PMP Course"],
          8
        ],
        address1
      );

      // Then update progress
      const { result } = simnet.callPublicFn(
        "career-progression",
        "update-skill-progress",
        [
          1, // plan-id
          50 // progress percentage
        ],
        address1
      );

      expect(result).toBeOk(true);
    });

    it("retrieves skill development plan", () => {
      // Create plan first
      simnet.callPublicFn(
        "career-progression",
        "create-skill-development-plan",
        [
          "communication",
          2,
          4,
          ["Public Speaking Course"],
          6
        ],
        address1
      );

      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-skill-development-plan",
        [address1, 1],
        address1
      );

      expect(result).toBeSome();
      if (result.type === "some") {
        expect(result.value).toHaveTupleKey("target-skill");
        expect(result.value["target-skill"]).toBePrincipalString("communication");
        expect(result.value["current-level"]).toBeUint(2);
      }
    });
  });

  describe("Career Recommendations", () => {
    it("generates recommendations for employee with goals", () => {
      // First set career goals
      simnet.callPublicFn(
        "career-progression",
        "set-career-goals",
        [
          ["Engineering Manager"],
          ["Technology"],
          150000,
          18,
          true,
          false
        ],
        address1
      );

      // Then generate recommendations
      const { result } = simnet.callPublicFn(
        "career-progression",
        "generate-recommendations",
        [address1],
        address1
      );

      expect(result).toBeOk(true);
    });

    it("fails to generate recommendations without goals", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "generate-recommendations",
        [address3], // address that hasn't set goals
        address3
      );

      expect(result).toBeErr(201); // err-not-found
    });
  });

  describe("Mentor Matching", () => {
    it("finds mentors for expertise area", () => {
      const { result } = simnet.callPublicFn(
        "career-progression",
        "find-mentors",
        ["leadership"],
        address1
      );

      expect(result).toBeOk();
      if (result.type === "ok") {
        expect(result.value).toHaveTupleKey("recommended-mentor");
        expect(result.value).toHaveTupleKey("expertise-match");
        expect(result.value["expertise-match"]).toBeBool(true);
      }
    });

    it("gets mentor availability", () => {
      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-mentor-availability",
        ["programming"],
        address1
      );

      expect(result).toBeOk();
      if (result.type === "ok") {
        expect(result.value).toHaveTupleKey("available-mentors");
        expect(result.value).toHaveTupleKey("avg-rating");
      }
    });
  });

  describe("Career Analytics", () => {
    it("provides career analytics for employee with goals and recommendations", () => {
      // Set goals
      simnet.callPublicFn(
        "career-progression",
        "set-career-goals",
        [
          ["Product Manager"],
          ["Technology"],
          130000,
          24,
          true,
          true
        ],
        address1
      );

      // Generate recommendations
      simnet.callPublicFn(
        "career-progression",
        "generate-recommendations",
        [address1],
        address1
      );

      const { result } = simnet.callReadOnlyFn(
        "career-progression",
        "get-career-analytics",
        [address1],
        address1
      );

      expect(result).toBeOk();
      if (result.type === "ok") {
        expect(result.value).toHaveTupleKey("goals-set");
        expect(result.value).toHaveTupleKey("recommendations-available");
        expect(result.value["goals-set"]).toBeBool(true);
      }
    });
  });
});

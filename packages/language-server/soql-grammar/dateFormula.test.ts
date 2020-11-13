import { isDateFormula } from "./dateFormula";

describe("isDateFormula returns", () => {
  it("false if input is not a DateFormula", () => {
    expect(isDateFormula("Hello")).toBeFalsy();
  });
  it("true if input is a DateFormula", () => {
    expect(isDateFormula("last_quarter")).toBeTruthy();
  });
});

import { isCurrency } from "./currencyLiteral";

describe("isCurrency returns", () => {
  it("false if input is not in currency format", () => {
    expect(isCurrency("hello")).toBeFalsy();
  });
  it("true if input is in currency format", () => {
    expect(isCurrency("abc123.45")).toBeTruthy();
  });
});

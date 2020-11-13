export function isCurrency(literalText: string): boolean {
  const currencyRegEx = /^[a-zA-Z]{3}[0-9]+\.*[0-9]*$/g;
  return currencyRegEx.test(literalText);
}

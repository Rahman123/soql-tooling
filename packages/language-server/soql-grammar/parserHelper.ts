import { TokenStream } from 'antlr4ts';
import * as CurrencyLiteral from './currencyLiteral';
import * as DateFormula from './dateFormula';

export class ParserHelper {
  private apiVersion: number;
  private apex: boolean;
  private multiCurrencyEnabled: boolean;
  constructor(
    apex: boolean,
    apiVersion: number,
    multiCurrencyEnabled: boolean
  ) {
    this.apiVersion = apiVersion;
    this.apex = apex;
    this.multiCurrencyEnabled = multiCurrencyEnabled;
  }
  public getApiVersion(): number {
    return this.apiVersion;
  }
  public isApex(): boolean {
    return this.apex;
  }
  public isMultiCurrencyEnabled(): boolean {
    return this.multiCurrencyEnabled;
  }
  public isCurrency(s: string | undefined): boolean {
    return typeof s === 'string' && CurrencyLiteral.isCurrency(s);
  }
  public isDateFormula(s: string | undefined): boolean {
    return typeof s === 'string' && DateFormula.isDateFormula(s);
  }

  public getLookaheadTokenText(
    tokenStream: TokenStream,
    i: number
  ): string | undefined {
    return tokenStream.LT(i).text;
  }
}

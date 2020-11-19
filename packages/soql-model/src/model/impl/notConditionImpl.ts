/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import * as Soql from '../model';
import { SoqlModelObjectImpl } from './soqlModelObjectImpl';

export class NotConditionImpl extends SoqlModelObjectImpl implements Soql.NotCondition {
  public condition: Soql.Condition;
  public constructor(condition: Soql.Condition) {
    super();
    this.condition = condition;
  }
  public toSoqlSyntax(options?: Soql.SyntaxOptions): string {
    return `NOT ${this.condition.toSoqlSyntax(options)}`;
  }
}

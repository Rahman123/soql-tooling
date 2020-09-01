/* 
 *  Copyright (c) 2020, salesforce.com, inc.
 *  All rights reserved.
 *  Licensed under the BSD 3-Clause license.
 *  For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *   
 */

import { LightningElement, api } from 'lwc';

export default class From extends LightningElement {
  @api sobjects: string[];
  @api selected: string;
  get filteredSObjects() {
    return this.sobjects.filter((sobject) => {
      return sobject !== this.selected;
    });
  }

  get hasSelected() {
    return !!this.selected;
  }

  handleSobjectSelection(e) {
    e.preventDefault();
    const selectedSobject = e.target.value;
    const sObjectSelected = new CustomEvent('objectselected', {
      detail: { selectedSobject }
    });
    this.dispatchEvent(sObjectSelected);
  }
}
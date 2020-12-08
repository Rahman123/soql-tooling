import { ToolingModelJson, ToolingModelService } from './toolingModelService';
import { JsonMap } from '@salesforce/ts-types';

export interface TelemetryModelJson extends JsonMap {
  sObject: string;
  fields: number;
  orderBy: JsonMap[];
  errors: JsonMap[];
  unsupported: string[];
  limit: string;
}

export function createQueryTelemetry(
  query: ToolingModelJson
): TelemetryModelJson {
  const telemetry = {} as TelemetryModelJson;
  telemetry.sObject = query.sObject.indexOf('__c') > -1 ? 'custom' : 'standard';
  telemetry.fields = query.fields.length;
  telemetry.orderBy = query.orderBy.map((orderBy) => {
    return {
      field: orderBy.field.indexOf('__c') > -1 ? 'custom' : 'standard',
      nulls: orderBy.nulls,
      order: orderBy.order
    };
  });
  telemetry.limit = query.limit;
  telemetry.errors = query.errors;
  telemetry.unsupported = query.unsupported;
  return telemetry;
}

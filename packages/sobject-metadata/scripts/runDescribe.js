#!/usr/bin/env node

// sample script for how to use SObjectDescriptAPI.describeObject() function

var api = require('../lib/describe/sobjectApi');
var sfcore = require('@salesforce/core');
const fs = require('fs');
const path = require('path');

var username = 'jhork@dev.com';
var sObjectName = 'Account';
var timestamp = '[last refresh timestamp]';
const resultsDataPath = path.join(__dirname, 'data');
const queryDataFileName = 'queryResults.json';

sfcore.AuthInfo.create({ username })
  .then((authInfo) => {
    sfcore.Connection.create({ authInfo }).then((connection) => {
      connection
        .query(
          'SELECT Name, Phone, AnnualRevenue, NumberOfEmployees, Id FROM Account'
        )
        .then((data) => {
          const records = data.records;
          // filter out the attributes key
          records.forEach((result) => delete result.attributes);
          const queryDataJson = JSON.stringify(records);
          fs.writeFileSync(
            `${resultsDataPath}/${queryDataFileName}`,
            queryDataJson
          );
        });

      console.log('You results are ready! 📈');

      /*       new api.SObjectDescribeAPI(connection)
        .describeSObject(sObjectName, timestamp)
        .then((result) => {
          const fields = result.result.fields.map((field) => field.name);
          console.log('Fields', fields);
          // console.log(JSON.stringify(result.fields, null, 2));
        })
        .catch((error) => {
          console.log(error);
        }); */
    });
  })
  .catch((error) => {
    console.log(error);
  });

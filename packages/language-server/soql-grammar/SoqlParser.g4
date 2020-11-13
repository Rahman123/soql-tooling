/*
 * Copyright 2020 salesforce.com, inc.
 * All Rights Reserved
 * Company Confidential
 */

/*
 * Grammar for the Salesforce Object Query Language (SOQL) parser.
 *
 * Naming Conventions:
 * We will use the following suffixes for rule names:
 *
 *   - "Clause": indicates a top level structure within a query, typically having a keyword followed
 *               by arguments. For example, "FROM account" is a clause within a query.
 *
 *   - "Expr":   indicates an argument that follows a key word in a clause. Typically, a keyword
 *               can be followed by one or more arguments, and the arguments can have one or more forms.
 *
 *   - "Value":  indicates a rule that has two alternatives: a literal and a colon expr;
 *               These rules are implemented using this template:
 *                   soqlXyzValue
 *                       : soqlXyz         #soqlLiteralXyzValue
 *                       | soqlColonExpr   #soqlColonExprXyzValue
 *                       ;
 *               for example, NumberValue can be a Number or a ColonExpr.
 *
 *   - "s":      indicates a collection.
 *
 */
parser grammar SoqlParser;
options { tokenVocab=SoqlLexer; }

import imports;

// These are things we want to parse in soql/sosl as well for soql fields.
// We have keywords that are sobject names.
// We should take keywords that are not and put them in parseReserved.
parseReservedForFieldName
    :   (
        ORDER
    |   DIVISION
    |   ALL
    |   DATA
    |   CATEGORY
    |   CATEGORY_AT
    |   CATEGORY_ABOVE
    |   CATEGORY_BELOW
    |   CATEGORY_ABOVE_OR_BELOW
    |   SOQL_OFFSET
    |   VIEW
    |   REFERENCE
    |   TYPEOF
    |   WHEN
    |   THEN
    |   SCOPE
    |   END
    |   DISTANCE
    |   GEOLOCATION
    |   GROUP
    |   CASE
    |   FIELDS
    |   PACKAGE
    |   IMPORT
    |   DEFAULT
    |   SWITCH
    |   COUNT
    )
    ;

soqlIdentifier :
    IDENTIFIER
    | parseReservedForFieldName
    // Not added COMMIT
    ;

soqlIdentifierNoReserved :
    IDENTIFIER
    ;

soqlIdentifiers
    :   soqlIdentifier (COMMA i=soqlIdentifier)*
    ;

soqlField
    : soqlIdentifier
    | soqlIdentifier LPAREN soqlIdentifier RPAREN        // Used to parse functions with one argument
    | soqlIdentifier LPAREN soqlIdentifier LPAREN soqlIdentifier RPAREN RPAREN // to parse functions with one nested argument
    ;

// Currently, only a polymorphic reference field can be used as the operand for TYPEOF.
soqlTypeofOperand
    : soqlField
    ;

// Only entity type name is supported as an operand for WHEN.
soqlWhenOperand
    : soqlIdentifier
    ;

// Currently, this can only be a field name.
soqlResultExpr
    : soqlField
    ;

soqlWhenExpr
    : WHEN soqlWhenOperand
      THEN soqlResultExpr (COMMA soqlResultExpr)*
    ;

soqlElseExpr
    : ELSE soqlResultExpr (COMMA soqlResultExpr)*
    ;

soqlTypeofExpr
    : TYPEOF soqlTypeofOperand
      soqlWhenExpr soqlWhenExpr*
      soqlElseExpr?
      END
    ;

soqlAlias
    : soqlIdentifier
    ;

// A numeric value that can be parsed into a Java int.
soqlInteger
    : (PLUS | MINUS)? INTEGER_LITERAL
    ;

soqlIntegerValue
    : soqlInteger                           #soqlLiteralIntegerValue
    | {this.helper.isApex()}? soqlColonExpr #soqlColonExprIntegerValue
    ;

// A numeric value that can be parsed into either a Java int or a Java BigDecimal.
soqlNumber
    : soqlInteger
    | (PLUS | MINUS)? DECIMAL_LITERAL
    ;

soqlNumberValue
    : soqlNumber                   #soqlLiteralNumberValue
/*  | {this.helper.isApex()}? soqlColonExpr #soqlColonExprNumberValue */
    ;

soqlGeolocationValue
    : GEOLOCATION LPAREN
          soqlNumberValue COMMA
          soqlNumberValue
      RPAREN                                #soqlLiteralGeolocationValue
/*  | {this.helper.isApex()}? soqlColonExpr #soqlColonExprGeolocationValue*/
    ;

soqlDistanceExpr
    : DISTANCE LPAREN
          soqlField COMMA
          soqlGeolocationValue COMMA
          nonValidatedEscapeStringLiteral
      RPAREN
    ;

soqlWhereClause
    :WHERE soqlWhereExprs                                #soqlWhereClauseMethod   // Had to give it this name because of the conflict.
    ;

soqlWhereExprs
    : soqlWhereExpr (soqlAndWhere | soqlOrWhere)?        #soqlWhereAndOrExpr
    | NOT soqlWhereExpr                                  #soqlWhereNotExpr
    ;

soqlAndWhere
    :(AND soqlWhereExpr)+
    ;

soqlOrWhere
    :(OR soqlWhereExpr)+
    ;

soqlWhereExpr
    :LPAREN soqlWhereExprs RPAREN                                                                #nestedWhereExpr
    | soqlIdentifier soqlCalcOperator soqlIdentifier soqlComparisonOperator soqlLiteralValue     #calculatedWhereExpr
    | soqlDistanceExpr soqlComparisonOperator soqlLiteralValue                                   #distanceWhereExpr
    | soqlField soqlComparisonOperator soqlLiteralValue                                          #simpleWhereExpr
    | soqlField LIKE soqlLikeValue                                                               #likeWhereExpr
    | soqlField soqlIncludesOperator LPAREN soqlLiteralValues RPAREN                             #includesWhereExpr
    | soqlField soqlInOperator LPAREN soqlSemiJoin RPAREN                                        #inWhereExprWithSemiJoin
    | soqlField soqlInOperator LPAREN soqlLiteralValues RPAREN                                   #inWhereExpr
    | soqlField soqlInOperator soqlColonExpr                                                     #inWhereExprForColonExpr
    ;

soqlCalcOperator
    : PLUS
    | MINUS
    ;

soqlLiteralValues
    :soqlLiteralValue (COMMA soqlLiteralValue)*
    ;

soqlIncludesOperator
    :   INCLUDES
    |   EXCLUDES
    ;

soqlInOperator
    :   IN
    |   NOT IN
    ;

soqlComparisonOperator
    :  EQ
    |  soqlCommonOperator
    ;

soqlCommonOperator
    :   NOT_EQ
    |   ALT_NOT_EQ
    |   LT EQ
    |   GT EQ
    |   LT
    |   GT
    ;

soqlLikeValue
    : soqlLikeLiteral                            #soqlLiteralLikeValue
    | soqlColonExpr                              #soqlColonLikeValue
    ;

soqlLikeLiteral
  : validatedEscapeLikeStringLiteral             #soqlLikeStringLiteral
  | soqlCommonLiterals                           #soqlLikeCommonLiterals
  ;

soqlCommonLiterals
      : DATE                                      #soqlDateLiteral
      | DATETIME                                  #soqlDateTimeLiteral
      | TIME                                      #soqlTimeLiteral
      | soqlNumberValue                           #soqlNumberLiteral
      | NULL                                      #soqlNullLiteral
      | (TRUE | FALSE)                            #soqlBooleanLiteral
      // The rules below are ambigous from the perpective of the parser because both of them are treated as identifiers.
      // as a result I have to use a semantic predicate to differentiate between them
      | {this.helper.isDateFormula(this.helper.getLookaheadTokenText(this._input, 1))}? IDENTIFIER (COLON INTEGER_LITERAL)?       #soqlDateFormulaLiteral
      | {this.helper.isMultiCurrencyEnabled() && this.helper.isCurrency(this.helper.getLookaheadTokenText(this._input, 1))}? IDENTIFIER    #soqlMultiCurrency
      ;

soqlLiteralValue
    : soqlLiteral                                #soqlLiteralLiteralValue
    | soqlColonExpr                              #soqlColonExprLiteralValue
    ;

soqlColonExpr
    : COLON IDENTIFIER
    ;

soqlLiteral
    : validatedEscapeStringLiteral              #soqlStringLiteral
    | soqlCommonLiterals                        #soqlLiteralCommonLiterals
    ;

nonValidatedEscapeStringLiteral
    : STR_START nonValidatedEscapeStringLiteralElement* STR_END;

nonValidatedEscapeStringLiteralElement
    : NEW_LINE
    | ESCAPE_CHAR INVALID_ESCAPE_CHAR
    | ESCAPE_CHAR VALID_ESCAPE_LIKE_CHAR
    | ESCAPE_CHAR VALID_ESCAPE_CHAR
    | ESCAPE_CHAR INVALID_ESCAPE_UNICODE
    | ESCAPE_CHAR ESCAPE_UNICODE
    | VALID_CHARS
    ;

validatedEscapeStringLiteral
    : STR_START validatedEscapeStringLiteralElement* STR_END;

validatedEscapeStringLiteralElement
    : ESCAPE_CHAR VALID_ESCAPE_LIKE_CHAR {this.notifyErrorListeners("Invalid Escape Character");}
    | validatedCommonSoqlStringLiteralElements
    ;

validatedEscapeLikeStringLiteral
     : STR_START validatedEscapeLikeStringLiteralElements* STR_END;

validatedEscapeLikeStringLiteralElements
    : ESCAPE_CHAR VALID_ESCAPE_LIKE_CHAR
    | validatedCommonSoqlStringLiteralElements
    ;

validatedCommonSoqlStringLiteralElements
    : NEW_LINE                           {this.notifyErrorListeners("Newline");}
    | ESCAPE_CHAR INVALID_ESCAPE_CHAR    {this.notifyErrorListeners("Invalid Escape Character");}
    | ESCAPE_CHAR VALID_ESCAPE_CHAR
    | ESCAPE_CHAR INVALID_ESCAPE_UNICODE {this.notifyErrorListeners("Invalid Unicode Character");}
    | ESCAPE_CHAR ESCAPE_UNICODE
    | VALID_CHARS
    ;

soqlSelectExpr
    : soqlField soqlAlias?                       #soqlSelectColumnExpr
    | LPAREN soqlInnerQuery RPAREN soqlAlias?    #soqlSelectInnerQueryExpr
    | soqlTypeofExpr soqlAlias?                  #soqlSelectTypeofExpr
    | soqlDistanceExpr  soqlAlias?               #soqlSelectDistanceExpr
    ;

soqlSelectExprs
    : soqlSelectExpr (COMMA soqlSelectExpr)*
    ;

soqlFromClause
    : FROM soqlFromExprs
    ;

soqlFromExprs
    : soqlFromExpr (COMMA soqlFromExpr)*
    ;

soqlFromExpr
    : soqlIdentifier (AS)? soqlIdentifier? soqlUsingClause?
    ;

soqlUsingClause
    : USING (
          {this.helper.getApiVersion() < 32.0}? soqlUsingPre192Expr
          | soqlUsingExprs
          )
    ;

soqlUsingPre192Expr
    : SCOPE soqlIdentifierNoReserved                                         #soqlUsingPre192ExprWithScope
    | soqlIdentifier soqlIdentifierNoReserved                                #soqlUsingPre192ExprDefault
    | soqlIdentifierNoReserved                                               #soqlUsingPre192ExprWithNoScope
    ;

soqlUsingExprs
    : soqlUsingExpr (COMMA soqlUsingExpr)*
    ;

soqlUsingExpr
   : SCOPE soqlIdentifierNoReserved                                          #soqlUsingScope
   | LOOKUP soqlIdentifierNoReserved                                         #soqlUsingLookup
   ;

soqlDataCategoryOperator
    : CATEGORY_AT
    | CATEGORY_ABOVE
    | CATEGORY_BELOW
    | CATEGORY_ABOVE_OR_BELOW
    ;

soqlDataCategoryExpr
    : soqlField
      soqlDataCategoryOperator
      (
          LPAREN soqlIdentifiers RPAREN
        | soqlIdentifier
      )
    ;

soqlWithValue
    : validatedEscapeStringLiteral             #soqlStringWithValue
/*  | {this.helper.isApex()}? soqlColonExpr             #soqlColonExprWithValue */
    ;

soqlWithKeyValue
    : soqlIdentifier EQ
      (
          validatedEscapeStringLiteral
        | INTEGER_LITERAL
        | TRUE
        | FALSE
      )
    ;

soqlWithClause
    : WITH DATA CATEGORY soqlDataCategoryExpr (AND soqlDataCategoryExpr)*  #soqlWithDataCategoryClause
    | WITH soqlIdentifier EQ soqlWithValue                                 #soqlWithEqualsClause
    ;

soqlWithIdentifierClause
    : WITH soqlIdentifier LPAREN soqlWithKeyValue (COMMA soqlWithKeyValue)* RPAREN   #soqlWithIdentifierTupleClause
    | WITH soqlIdentifier                                                            #soqlWithSingleIdentifierClause
    ;

soqlLimitClause
    : LIMIT soqlIntegerValue
    ;

soqlOffsetClause
    : SOQL_OFFSET soqlIntegerValue
    ;

soqlGroupByExprs
    : soqlField (COMMA soqlField)*
    ;

soqlGroupByClause
    : GROUP BY
      (
          (ROLLUP | CUBE) LPAREN soqlGroupByExprs RPAREN
        | soqlGroupByExprs
      ) soqlHavingClause?
    ;

soqlHavingClause
    : HAVING soqlWhereExprs
    ;

soqlOrderByClauseField
    :   soqlField                   #soqlOrderByColumnExpr
    |   soqlDistanceExpr            #soqlOrderByDistanceExpr
    ;

soqlOrderByClauseExpr
    : soqlOrderByClauseField
      (ASC | DESC)?
      (NULLS
            ( FIRST | LAST)
      )?
    ;

soqlOrderByClauseExprs
    : soqlOrderByClauseExpr (COMMA soqlOrderByClauseExpr)*
    ;

soqlOrderByClause
    : ORDER BY soqlOrderByClauseExprs
    ;

soqlBindClauseExpr
    : soqlIdentifier EQ soqlLiteral
    ;

soqlBindClauseExprs
    : soqlBindClauseExpr (COMMA soqlBindClauseExpr)*
    ;

soqlBindClause
    : BIND soqlBindClauseExprs
    ;

soqlRecordTrackingType
    : FOR VIEW               #soqlForView
    | FOR REFERENCE          #soqlForReference
    ;

soqlUpdateStatsClause
    : UPDATE soqlIdentifiers
    ;

soqlSelectClause
    : SELECT COUNT LPAREN RPAREN       #soqlSelectCountClause
    | SELECT soqlSelectExprs           #soqlSelectExprsClause
    ;

soqlSemiJoin
    : SELECT soqlField
      soqlFromClause
      soqlWhereClause?
      soqlWithClause?
    ;

soqlInnerQuery
    : soqlSelectClause
      soqlFromClause
      soqlWhereClause?
      soqlWithClause?
      soqlWithIdentifierClause*
      soqlGroupByClause?
      soqlOrderByClause?
      soqlLimitClause?
      soqlOffsetClause?
      soqlBindClause?
      soqlRecordTrackingType?
      soqlUpdateStatsClause?
    ;

soqlQuery
    : soqlInnerQuery EOF
    ;

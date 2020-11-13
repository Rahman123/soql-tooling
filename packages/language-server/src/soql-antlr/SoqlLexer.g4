lexer grammar SoqlLexer;

MINUS : '-';
TILDE : '~';
PLUS : '+';
TIMES : '*';
DIVIDE : '/';
LPAREN : '(';
RPAREN : ')';
COMMA : ',';

AND : 'and';
OR : 'or';
TRUE : 'true';
FALSE : 'false';
DIVISION : 'division';
WITH : 'with';
DATA : 'data';
CATEGORY : 'category';
CATEGORY_AT : 'at';
CATEGORY_ABOVE : 'above';
CATEGORY_BELOW : 'below';
CATEGORY_ABOVE_OR_BELOW : 'above_or_below';
SOQL_OFFSET : 'offset';
FOR : 'for';
VIEW : 'view';
LIMIT : 'limit';
REFERENCE : 'reference';
TYPEOF : 'typeof';
WHEN : 'when';
WHERE: 'where';
THEN : 'then';
ELSE : 'else';
END : 'end';
DISTANCE : 'distance';
GEOLOCATION : 'geolocation';
GROUP : 'group';
ROLLUP : 'rollup';
CUBE : 'cube';
HAVING : 'having';
INCLUDES:'includes';
EXCLUDES: 'excludes';
ORDER : 'order';
IN: 'in';
NOT: 'not';
BY : 'by';
ASC : 'asc';
DESC : 'desc';
NULLS : 'nulls';
CASE : 'case';
FIELDS : 'fields';
PACKAGE : 'package';
DEFAULT : 'default';
IMPORT : 'import';
SWITCH : 'switch';
SELECT: 'select';
COUNT: 'count';
FROM: 'from';
LOOKUP: 'lookup';
SCOPE: 'scope';
AS: 'as';
USING: 'using';
NULL: 'null';
UPDATE: 'update';
FIRST : 'first';
LAST : 'last';
LIKE: 'like';
BIND : 'bind';

IDENTIFIER
    :    IDENTIFIER_START (IDENTIFIER_CHAR)*
    ;

fragment
IDENTIFIER_START
    :   LETTER
    |   '_'
    |   '$'
    ;

fragment
LETTER
    : 'a'..'z' | 'A'..'Z'
    ;

fragment
IDENTIFIER_CHAR
    :   IDENTIFIER_START
    |   DIGIT
    |   MISC_NON_START_IDENTIFIER_CHAR
    |   DOT
    ;

/// MISC_NON_START_IDENTIFIER_CHAR is the stuff that can be in an identifier but isn't valid at the start of an identifier
fragment
MISC_NON_START_IDENTIFIER_CHAR
    :   '\u0080'..'\ufffe'
    ;

fragment
DIGIT
    :    '0'..'9'
    ;

DOT
    :   '.'
    ;

COLON
    :   ':'
    ;

WS
    :   ( ' ' | TAB | CR | LF)+ -> skip
    ;

fragment
CR
        : '\r'
        ;

    // line feed
    fragment
    LF
        : '\n'
        ;

    // tab
    fragment
    TAB
        : '\t'
        ;


// single char punctuation and operators
EQ
    :   '='
    ;

LT
    :   '<'
    ;

GT
    :   '>'
    ;

NOT_EQ
    :   '!''='
    ;

ALT_NOT_EQ
    :   '<''>'
    ;

fragment
INTEGER
    :   DIGIT+
    ;

// Represents a sequence of one or more digits
// that can be interpretted as a base-10 whole number.
INTEGER_LITERAL
    :   INTEGER
    ;

DECIMAL_LITERAL
    :   INTEGER? DOT INTEGER
    ;

STR_START: '\'' -> pushMode(PARSE_STRING_WITH_ESCAPES);
// 4 digit year, no restrictions.
fragment
YEAR
    :   DIGIT DIGIT DIGIT DIGIT
    ;

// months from 1 to 12
fragment
MONTH
    :  DIGIT DIGIT
    ;


// date from 01 to 31.  Doesn't check month.
fragment
DAY
    :  DIGIT DIGIT
    ;


// hour from 00 to 23.
fragment
HOUR
    :  DIGIT DIGIT
    ;


// minute from 00 to 59
fragment
MINUTE
    :   DIGIT DIGIT
    ;

// From the spec, you can have 60 seconds in a minute when there is a leap second.
fragment
SECOND
    :  DIGIT DIGIT
    ;


// A timezone offset of the form +/- HH:MM or +/- HHMM.
fragment
OFFSET
    :   ( PLUS | MINUS ) HOUR (COLON)? MINUTE
    ;


// the date part of a DATETIME
fragment
DATEPART
    :   YEAR MINUS MONTH MINUS DAY
    ;


// the hours, minuts, seconds, and millis of a TIME, or DATETIME
fragment
TIME_PART_WITHOUT_OFFSET
    :   HOUR COLON MINUTE COLON SECOND (DOT INTEGER)?
    ;

DATE:
    DATEPART;


DATETIME:
    DATEPART ('t' TIME_PART_WITHOUT_OFFSET ('z'|OFFSET))?
    ;


TIME
    : TIME_PART_WITHOUT_OFFSET ('z' | OFFSET)
    ;


mode PARSE_STRING_WITH_ESCAPES;
ESCAPE_CHAR: '\\' -> pushMode(ESCAPE_CHARS);
VALID_CHARS: ~('\'' | '\\' | '\n')*;
NEW_LINE: '\n';
STR_END: '\'' -> popMode;
mode ESCAPE_CHARS;
VALID_ESCAPE_CHAR: ('n' | 'N' | 'r' | 'R' | 't' | 'T' | 'b' | 'B' | '\'' | '"' | '\\') -> popMode;
VALID_ESCAPE_LIKE_CHAR: ('%' | '_') -> popMode;
INVALID_ESCAPE_CHAR: ~('n' | 'N' | 'r' | 'R' | 't' | 'T' | 'b' | 'B' | '%' | '\'' | '"' | '_' | '\\') -> popMode;
INVALID_ESCAPE_UNICODE: 'u' ('f'|'F') ('f'|'F') ('f'|'F') ('f'|'F') -> popMode;
ESCAPE_UNICODE: 'u' HEX_DIGIT_1 HEX_DIGIT_1 HEX_DIGIT_1 HEX_DIGIT_1 -> popMode;
HEX_DIGIT_1: ('a'..'f'|'A'..'F'|'0'..'9');

/*

Copyright (C) 2014  Michigan State University Board of Trustees

The JavaScript code in this page is free software: you can
redistribute it and/or modify it under the terms of the GNU
General Public License (GNU GPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.  The code is distributed WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU GPL for more details.

As additional permission under GNU GPL version 3 section 7, you
may distribute non-source (e.g., minimized or compacted) forms of
that code without the copy of the GNU GPL normally required by
section 4, provided you include this license notice and a URL
through which recipients can access the Corresponding Source.

*/

"use strict";

/**
 * Operator definitions (see function define() at the end).
 * @constructor
 */
function Definitions() {
    this.operators = [];  /* Array of Operator */
}

Definitions.ARG_SEPARATOR = ";";
Definitions.DECIMAL_SIGN_1 = ".";
Definitions.DECIMAL_SIGN_2 = ",";
Definitions.INTERVAL_SEPARATOR = ":";

/**
 * Creates a new operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} arity - Operator.UNARY, BINARY or TERNARY
 * @param {number} lbp - Left binding power
 * @param {number} rbp - Right binding power
 * @param {function} nud - Null denotation function
 * @param {function} led - Left denotation function
 */
Definitions.prototype.operator = function(id, arity, lbp, rbp, nud, led) {
    this.operators.push(new Operator(id, arity, lbp, rbp, nud, led));
};

/**
 * Creates a new separator operator.
 * @param {string} id - Operator id (text used to recognize it)
 */
Definitions.prototype.separator = function(id) {
    this.operator(id, Operator.BINARY, 0, 0, null, null);
};

/**
 * Creates a new infix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} lbp - Left binding power
 * @param {number} rbp - Right binding power
 * @param {ledFunction} [led] - Left denotation function
 */
Definitions.prototype.infix = function(id, lbp, rbp, led) {
    var arity, nud;
    arity = Operator.BINARY;
    nud = null;
    led = led || function(p, left) {
        var children = [left, p.expression(rbp)];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Creates a new prefix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} rbp - Right binding power
 * @param {nudFunction} [nud] - Null denotation function
 */
Definitions.prototype.prefix = function(id, rbp, nud) {
    var arity, lbp, led;
    arity = Operator.UNARY;
    lbp = 0;
    nud = nud || function(p) {
        var children = [p.expression(rbp)];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    led = null;
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Creates a new suffix operator.
 * @param {string} id - Operator id (text used to recognize it)
 * @param {number} lbp - Left binding power
 * @param {ledFunction} [led] - Left denotation function
 */
Definitions.prototype.suffix = function(id, lbp, led) {
    var arity, rbp, nud;
    arity = Operator.UNARY;
    rbp = 0;
    nud = null;
    led = led || function(p, left) {
        var children = [left];
        return new ENode(ENode.OPERATOR, this, id, children);
    };
    this.operator(id, arity, lbp, rbp, nud, led);
};

/**
 * Returns the defined operator with the given id
 * @param {string} id - Operator id (text used to recognize it)
 * @returns {Operator}
 */
Definitions.prototype.findOperator = function(id) {
    for (var i=0; i<this.operators.length; i++) {
        if (this.operators[i].id == id) {
            return(this.operators[i]);
        }
    }
    return null;
}

/**
 * Returns the ENode for the interval, parsing starting just before the interval separator
 * @param {boolean} closed - was the first operator closed ?
 * @param {ENode} e1 - First argument (already parsed)
 * @param {Operator} op - The operator
 * @param {Parser} p - The parser
 * @returns {ENode}
 */
Definitions.prototype.buildInterval = function(closed, e1, op, p) {
    p.advance(Definitions.INTERVAL_SEPARATOR);
    var e2 = p.expression(0);
    if (p.current_token == null || p.current_token.op == null ||
            (p.current_token.op.id !== ")" && p.current_token.op.id !== "]")) {
        throw new ParseException("Wrong interval syntax.", p.tokens[p.token_nr - 1].from);
    }
    var interval_type;
    if (p.current_token.op.id == ")") {
        p.advance(")");
        if (closed)
            interval_type = ENode.CLOSED_OPEN;
        else
            interval_type = ENode.OPEN_OPEN;
    } else {
        p.advance("]");
        if (closed)
            interval_type = ENode.CLOSED_CLOSED;
        else
            interval_type = ENode.OPEN_CLOSED;
    }
    return new ENode(ENode.INTERVAL, op, null, [e1, e2], interval_type);
}

/**
 * Defines all the operators.
 */
Definitions.prototype.define = function() {
    this.suffix("!", 160);
    this.infix("^", 140, 139);
    this.infix(".", 130, 129);
    this.infix("`", 125, 125, function(p, left) {
        // led (infix operator)
        // this led for units gathers all the units in an ENode
        var right = p.expression(125);
        while (p.current_token != null && "*/".indexOf(p.current_token.value) != -1) {
            var token2 = p.tokens[p.token_nr];
            if (token2 == null)
                break;
            if (token2.type != Token.NAME && token2.value != "(")
                break;
            var token3 = p.tokens[p.token_nr+1];
            if (token3 != null && (token3.value == "(" || token3.type == Token.NUMBER))
                break;
            if (p.unit_mode && p.tokens[p.token_nr].type == Token.NAME) {
                var nv = p.tokens[p.token_nr].value;
                var cst = false;
                for (var i=0; i<p.constants.length; i++) {
                    if (nv == p.constants[i]) {
                        cst = true;
                        break;
                    }
                }
                if (cst)
                    break;
            }
            var t = p.current_token;
            p.advance();
            right = t.op.led(p, right);
        }
        var children = [left, right];
        return new ENode(ENode.OPERATOR, this, "`", children);
    });
    this.infix("*", 120, 120);
    this.infix("/", 120, 120);
    this.infix("%", 120, 120);
    this.infix("+", 100, 100);
    this.operator("-", Operator.BINARY, 100, 134, function(p) {
        // nud (prefix operator)
        var children = [p.expression(134)];
        return new ENode(ENode.OPERATOR, this, "-", children);
    }, function(p, left) {
        // led (infix operator)
        var children = [left, p.expression(100)];
        return new ENode(ENode.OPERATOR, this, "-", children);
    });
    this.infix("=", 80, 80);
    this.infix("#", 80, 80);
    this.infix("<=", 80, 80);
    this.infix(">=", 80, 80);
    this.infix("<", 80, 80);
    this.infix(">", 80, 80);
    
    this.separator(")");
    this.separator(Definitions.ARG_SEPARATOR);
    this.separator(Definitions.INTERVAL_SEPARATOR);
    var defs = this;
    this.operator("(", Operator.BINARY, 200, 200, function(p) {
        // nud (for parenthesis and intervals)
        var e = p.expression(0);
        if (p.current_token != null && p.current_token.op != null &&
                p.current_token.op.id == Definitions.INTERVAL_SEPARATOR) {
            return defs.buildInterval(false, e, this, p);
        }
        p.advance(")");
        return e;
    }, function(p, left) {
        // led (for functions)
        if (left.type != ENode.NAME && left.type != ENode.SUBSCRIPT)
            throw new ParseException("Function name expected before a parenthesis.", p.tokens[p.token_nr - 1].from);
        var children = [left];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== ")") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance(")");
        return new ENode(ENode.FUNCTION, this, "(", children);
    });
    
    this.separator("]");
    this.operator("[", Operator.BINARY, 200, 70, function(p) {
        // nud (for vectors and intervals)
        var children = [];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== "]") {
            var e = p.expression(0);
            if (p.current_token != null && p.current_token.op != null &&
                    p.current_token.op.id == Definitions.INTERVAL_SEPARATOR) {
                return defs.buildInterval(true, e, this, p);
            }
            while (true) {
                children.push(e);
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
                e = p.expression(0);
            }
        }
        p.advance("]");
        return new ENode(ENode.VECTOR, this, null, children);
    }, function(p, left) {
        // led (for subscript)
        if (left.type != ENode.NAME && left.type != ENode.SUBSCRIPT)
            throw new ParseException("Name expected before a square bracket.", p.tokens[p.token_nr - 1].from);
        var children = [left];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== "]") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance("]");
        return new ENode(ENode.SUBSCRIPT, this, "[", children);
    });
    
    this.separator("}");
    this.prefix("{", 200, function(p) {
        // nud (for sets)
        var children = [];
        if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== "}") {
            while (true) {
                children.push(p.expression(0));
                if (p.current_token == null || p.current_token.op == null || p.current_token.op.id !== Definitions.ARG_SEPARATOR) {
                    break;
                }
                p.advance(Definitions.ARG_SEPARATOR);
            }
        }
        p.advance("}");
        return new ENode(ENode.SET, this, null, children);
    });
    this.prefix("$", 300, function(p) {
        // Perl variables
        var e = p.expression(300);
        if (e.type != ENode.NAME)
            throw new ParseException("Variable name expected after a $.", p.tokens[p.token_nr - 1].from);
        e.value = '$' + e.value;
        return e;
    });
};


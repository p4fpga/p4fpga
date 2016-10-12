
// Copyright (c) 2016 Massachusetts Institute of Technology

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package StringUtils;

// A set of functions for helping with compile-time string manipulation

import List::*;

// splits a string with a comma at the first comma
// examples:
//  "testing,,hello,world" -> "testing" ",hello,world"
//  ",hello,world"         -> ""        "hello,world"
//  "hello,world"          -> "hello"   "world"
//  "world"                -> "world"   ""
function Tuple2#(String, String) splitStringAtComma(String in);
    List#(Char) charList = stringToCharList(in);
    function Bool notComma(Char c);
        return c != ",";
    endfunction
    // take everything up to the first comma
    let parsedEntry = charListToString(takeWhile(notComma, charList));
    // drop everything up to the first comma, then drop that too
    let restOfString = charListToString(drop(1, dropWhile(notComma, charList)));
    return tuple2(parsedEntry, restOfString);
endfunction

// splits a CSV string into a list of the strings between commas
// example:
//  "testing,,hello,world" -> "testing" "" "hello" "world"
function List#(String) parseCSV(String inStr);
    String restOfString = inStr;
    List#(String) parsedResult = tagged Nil;
    while (restOfString != "") begin
        match {.newElement, .newRestOfString} = splitStringAtComma(restOfString);
        parsedResult = List::cons(newElement, parsedResult);
        restOfString = newRestOfString;
    end
    return reverse(parsedResult);
endfunction

function Integer decStringToInteger(String inStr);
    List#(Char) inCharList = stringToCharList(inStr);
    // sanity check 1
    if (!List::all(isDigit, inCharList)) begin
        let x = error("decStringToInteger used on non decString string: " + doubleQuote(inStr));
    end
    // recursion helper function
    function Tuple2#(Integer, List#(Char)) decStringToIntegerHelper(Integer i, List#(Char) in);
        if (in == tagged Nil) begin
            return tuple2(i, in);
        end else begin
            return decStringToIntegerHelper(10*i + digitToInteger(head(in)), tail(in));
        end
    endfunction
    // using recursion helper function
    let {parsedInt, shouldBeNil} = decStringToIntegerHelper(0, inCharList);
    // sanity check 2
    if (shouldBeNil != tagged Nil) begin
        let x = error("in decStringToInteger, shouldBeNil was not Nil");
    end
    return parsedInt;
endfunction

function Integer hexStringToInteger(String inStr);
    List#(Char) inCharList = stringToCharList(inStr);
    // possibly chop off "0x"
    if (length(inCharList) >= 2) begin
        let firstTwoChars = charListToString(take(2, inCharList));
        if (firstTwoChars == "0x") begin
            inCharList = drop(2, inCharList);
        end
    end
    // sanity check 1
    if (!List::all(isHexDigit, inCharList)) begin
        let x = error("hexStringToInteger used on non hexString string: " + doubleQuote(inStr));
    end
    // recursion helper function
    function Tuple2#(Integer, List#(Char)) hexStringToIntegerHelper(Integer i, List#(Char) in);
        if (in == tagged Nil) begin
            return tuple2(i, in);
        end else begin
            return hexStringToIntegerHelper(16*i + hexDigitToInteger(head(in)), tail(in));
        end
    endfunction
    // using recursion helper function
    let {parsedInt, shouldBeNil} = hexStringToIntegerHelper(0, inCharList);
    // sanity check 2
    if (shouldBeNil != tagged Nil) begin
        let x = error("in hexStringToInteger, shouldBeNil was not Nil");
    end
    return parsedInt;
endfunction

function String doubleQuotedToString(String inStr);
    List#(Char) inCharList = stringToCharList(inStr);
    // sanity check 1
    if ((head(inCharList) != "\"") || (last(inCharList) != "\"")) begin
        let x = error("doubleQuotedToString used on non-double-quoted string: " + inStr);
    end
    return charListToString(init(tail(inCharList)));
endfunction

endpackage

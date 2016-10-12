//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

import List::*;

//
// An easier way of building lists, similar to tuple().
//

function List#(t_DATA) list1(t_DATA a0) = List::cons(a0, List::nil);
function List#(t_DATA) list2(t_DATA a0, t_DATA a1) = List::cons(a0, List::cons(a1, List::nil));
function List#(t_DATA) list3(t_DATA a0, t_DATA a1, t_DATA a2) = List::cons(a0, List::cons(a1, List::cons(a2, List::nil)));
function List#(t_DATA) list4(t_DATA a0, t_DATA a1, t_DATA a2, t_DATA a3) = List::cons(a0, List::cons(a1, List::cons(a2, List::cons(a3, List::nil))));
function List#(t_DATA) list5(t_DATA a0, t_DATA a1, t_DATA a2, t_DATA a3, t_DATA a4) = List::cons(a0, List::cons(a1, List::cons(a2, List::cons(a3, List::cons(a4, List::nil)))));
function List#(t_DATA) list6(t_DATA a0, t_DATA a1, t_DATA a2, t_DATA a3, t_DATA a4, t_DATA a5) = List::cons(a0, List::cons(a1, List::cons(a2, List::cons(a3, List::cons(a4, List::cons(a5, List::nil))))));
function List#(t_DATA) list7(t_DATA a0, t_DATA a1, t_DATA a2, t_DATA a3, t_DATA a4, t_DATA a5, t_DATA a6) = List::cons(a0, List::cons(a1, List::cons(a2, List::cons(a3, List::cons(a4, List::cons(a5, List::cons(a6, List::nil)))))));
function List#(t_DATA) list8(t_DATA a0, t_DATA a1, t_DATA a2, t_DATA a3, t_DATA a4, t_DATA a5, t_DATA a6, t_DATA a7) = List::cons(a0, List::cons(a1, List::cons(a2, List::cons(a3, List::cons(a4, List::cons(a5, List::cons(a6, List::cons(a7, List::nil))))))));
    
    
//
// Provided by Bluespec -- method of generating arbitrary length lists
// using just list(a, b, ...).
//

// A type class used to implement a list construction function
// which can take any number of arguments (>0).
// The type a is the type of list elements.  The type r is the
// remainder of the curried type.
// So with 3 arguments, there would be three instance matches
// used for BuildList:
//   one with r equal to List#(a)
//   one with r equal to function List#(a) f(a x)
//   one with r equal to function (function List#(a) f1(a x)) f2(a x)

// The type class definition
typeclass BuildList#(type a, type r)
    dependencies (r determines a);
    function r buildList_(List#(a) l, a x);
endtypeclass

// This is the base case (building a list from the final argument)
instance BuildList#(a,List#(a));
    function List#(a) buildList_(List#(a) l, a x);
        return List::reverse(List::cons(x,l));
    endfunction
endinstance

// This is the recursive case (building a list from non-final
// arguments)
// Note: this plays the trick of moving a function
// application from the return type into the argument list -- the
// overall type of buildList_ is the same, but it is written in a way
// that allows us to manipulate the curried argument.
instance BuildList#(a,function r f(a x)) provisos(BuildList#(a,r));
    function r buildList_(List#(a) l, a x, a y);
        return buildList_(List::cons(x,l),y);
    endfunction
endinstance

// This is the user-visible List constructor function
function r list(a x) provisos(BuildList#(a,r));
    return buildList_(List::nil,x);
endfunction

--[[
	
	This file contains tests for my libs
	To test, just run this file
	
]]--

local ufo = require "ufo"

-- Helper function
function assertEquals( a, b )
	assert( a == b, "Expected '"..tostring(a).."', got '"..tostring(b).."'" )
end



-- TEST DEFINITIONS

function ufoConvertToFilename()
	assertEquals( "a",                ufo.convertToFilename("a") )
	assertEquals( "A_",               ufo.convertToFilename("A") )
	assertEquals( "A_E_",             ufo.convertToFilename("AE") )
	assertEquals( "A_e",              ufo.convertToFilename("Ae") )
	assertEquals( "ae",               ufo.convertToFilename("ae") )
	assertEquals( "aE_",              ufo.convertToFilename("aE") )
	assertEquals( "a.alt",            ufo.convertToFilename("a.alt") )
	assertEquals( "A_.alt",           ufo.convertToFilename("A.alt") )
	assertEquals( "A_.A_lt",          ufo.convertToFilename("A.Alt") )
	assertEquals( "A_.aL_t",          ufo.convertToFilename("A.aLt") )
	assertEquals( "A_.alT_",          ufo.convertToFilename("A.alT") )
	assertEquals( "T__H_",            ufo.convertToFilename("T_H") )
	assertEquals( "T__h",             ufo.convertToFilename("T_h") )
	assertEquals( "t_h",              ufo.convertToFilename("t_h") )
	assertEquals( "F__F__I_",         ufo.convertToFilename("F_F_I") )
	assertEquals( "f_f_i",            ufo.convertToFilename("f_f_i") )
	assertEquals( "A_acute_V_.swash", ufo.convertToFilename("Aacute_V.swash") )
	assertEquals( "_notdef",          ufo.convertToFilename(".notdef") )
	assertEquals( "_con",             ufo.convertToFilename("con") )
	assertEquals( "C_O_N_",           ufo.convertToFilename("CON") )
	assertEquals( "_con.alt",         ufo.convertToFilename("con.alt") )
	assertEquals( "alt._con",         ufo.convertToFilename("alt.con") )
end



-- RUN TESTS

ufoConvertToFilename()
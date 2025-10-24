module test;
parameter W=4;
// Test 1: Boolean array (what failed before)
logic bool_mem [W == 1 ? 0 : -1 : 0];

// Test 2: Vector array (what works now) 
logic [31:28] vec_mem [W == 1 ? 0 : -1 : 0];

// Test 3: For comparison - normal arrays
logic normal_bool [1:0];
logic [31:28] normal_vec [1:0];
endmodule

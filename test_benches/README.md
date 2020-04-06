<b>Test benches for SimpleCPU </b>
<br>The following test benches have been created:

<pre class="tab">
<br>top_level.vdl
<br>control_unit.vhd
<br>ALU_tb.vhd for explicitly testing the ALU.vhd
<br>ROM_tb.vhd for explicitly testing the ROM.vhd
</pre>
<br>The following test benches test the functionality of the entire CPU by loading some simple programs 
<br>that are written in machine code.
<pre class="tab">
<br>add_tb.vhd       -program for adding 1+1
<br>counter_tb.vhd   -program of a counter that counts from 0 to 20
<br>fibonacci_tb.vhd -program that calculates the first 17 fibonacci numbers
</pre>


import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
import logging
import util

@cocotb.test()
async def main(dut):
    await util.init(dut)
    await Timer(30, 'us')
    for i in [1,2,3,4,10]:
        await portTest(dut, i)
        dut._log.info("Test passed on port {}".format(i))

async def portTest(dut, i):
    assert await util.RMAPread(dut, i, 0x2124) == 1 # Port 1 Link up count

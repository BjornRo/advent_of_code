import asyncio
from collections import defaultdict

with open("in/d18.txt") as f:
    data = [x.rstrip().split(" ") for x in f]


async def program(uid: int, send_queue: asyncio.Queue, recv_queue: asyncio.Queue):
    reg_or_val = lambda registers, value: registers[value] if value.isalpha() else int(value)
    registers = defaultdict(int)
    registers["p"] = uid
    sent = 0
    pc = 0
    while pc <= len(data):
        ins = data[pc]
        pc += 1
        match ins:
            case "set", reg, val:
                registers[reg] = reg_or_val(registers, val)
            case "add", reg, val:
                registers[reg] += reg_or_val(registers, val)
            case "mul", reg, val:
                registers[reg] *= reg_or_val(registers, val)
            case "mod", reg, val:
                registers[reg] %= reg_or_val(registers, val)
            case "jgz", reg, val:
                if reg_or_val(registers, reg) > 0:
                    pc += reg_or_val(registers, val) - 1
            case "snd", reg:
                await send_queue.put(registers[reg])
                sent += 1
            case "rcv", reg:
                if sent != 0 and recv_queue.empty() and send_queue.empty():
                    return sent
                if send_queue is recv_queue:
                    return recv_queue._queue[-1]  # type:ignore
                value = await recv_queue.get()
                registers[reg] = value


async def solver():
    a_queue = asyncio.Queue()
    p1_result = await program(0, send_queue=a_queue, recv_queue=a_queue)

    a_queue = asyncio.Queue()
    b_queue = asyncio.Queue()
    task_a = asyncio.create_task(program(0, send_queue=b_queue, recv_queue=a_queue))
    return p1_result, await program(1, send_queue=a_queue, recv_queue=b_queue)


p1, p2 = asyncio.run(solver())
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")

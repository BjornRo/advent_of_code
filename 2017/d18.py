import asyncio
from collections import defaultdict

with open("in/d18.txt") as f:
    data = [x.rstrip().split(" ") for x in f]


async def program(
    uid: int,
    signal: asyncio.Event,
    send_queue: asyncio.Queue,
    recv_queue: asyncio.Queue,
):
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
                if sent != 0:
                    if recv_queue.empty() and send_queue.empty():
                        signal.set()
                if send_queue is recv_queue:
                    return recv_queue._queue[-1]  # type:ignore
                value = await recv_queue.get()
                if value == -1:
                    return sent
                registers[reg] = value

                signal.clear()


async def solver():
    signal = asyncio.Event()
    a_queue = asyncio.Queue()
    p1_result = await program(0, signal, send_queue=a_queue, recv_queue=a_queue)

    signal = asyncio.Event()
    a_queue = asyncio.Queue()
    b_queue = asyncio.Queue()

    task_a = asyncio.create_task(program(0, signal, send_queue=b_queue, recv_queue=a_queue))
    task_b = asyncio.create_task(program(1, signal, send_queue=a_queue, recv_queue=b_queue))

    await signal.wait()
    await b_queue.put(-1)
    return p1_result, await task_b


p1, p2 = asyncio.run(solver())
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")

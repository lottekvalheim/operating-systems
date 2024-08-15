
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9e070713          	addi	a4,a4,-1568 # 80008a30 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	00e78793          	addi	a5,a5,14 # 80006070 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc75f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	666080e7          	jalr	1638(ra) # 80002790 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	9e650513          	addi	a0,a0,-1562 # 80010b70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9d648493          	addi	s1,s1,-1578 # 80010b70 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a6690913          	addi	s2,s2,-1434 # 80010c08 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9c4080e7          	jalr	-1596(ra) # 80001b84 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	412080e7          	jalr	1042(ra) # 800025da <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	15c080e7          	jalr	348(ra) # 80002332 <sleep>
        while (cons.r == cons.w)
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	528080e7          	jalr	1320(ra) # 8000273a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	94a50513          	addi	a0,a0,-1718 # 80010b70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	93450513          	addi	a0,a0,-1740 # 80010b70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	98f72b23          	sw	a5,-1642(a4) # 80010c08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8a450513          	addi	a0,a0,-1884 # 80010b70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	4f4080e7          	jalr	1268(ra) # 800027e6 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	87650513          	addi	a0,a0,-1930 # 80010b70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	85270713          	addi	a4,a4,-1966 # 80010b70 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
            consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	82878793          	addi	a5,a5,-2008 # 80010b70 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8927a783          	lw	a5,-1902(a5) # 80010c08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7e670713          	addi	a4,a4,2022 # 80010b70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7d648493          	addi	s1,s1,2006 # 80010b70 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	79a70713          	addi	a4,a4,1946 # 80010b70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	82f72223          	sw	a5,-2012(a4) # 80010c10 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	75e78793          	addi	a5,a5,1886 # 80010b70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7cc7ab23          	sw	a2,2006(a5) # 80010c0c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ca50513          	addi	a0,a0,1994 # 80010c08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f50080e7          	jalr	-176(ra) # 80002396 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	71050513          	addi	a0,a0,1808 # 80010b70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	a9078793          	addi	a5,a5,-1392 # 80020f08 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6e07a223          	sw	zero,1764(a5) # 80010c30 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	46f72823          	sw	a5,1136(a4) # 800089f0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	674dad83          	lw	s11,1652(s11) # 80010c30 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	61e50513          	addi	a0,a0,1566 # 80010c18 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	4c050513          	addi	a0,a0,1216 # 80010c18 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	4a448493          	addi	s1,s1,1188 # 80010c18 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	46450513          	addi	a0,a0,1124 # 80010c38 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1f07a783          	lw	a5,496(a5) # 800089f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1c07b783          	ld	a5,448(a5) # 800089f8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	1c073703          	ld	a4,448(a4) # 80008a00 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	3d6a0a13          	addi	s4,s4,982 # 80010c38 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	18e48493          	addi	s1,s1,398 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	18e98993          	addi	s3,s3,398 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b02080e7          	jalr	-1278(ra) # 80002396 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	36850513          	addi	a0,a0,872 # 80010c38 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1107a783          	lw	a5,272(a5) # 800089f0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	11673703          	ld	a4,278(a4) # 80008a00 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1067b783          	ld	a5,262(a5) # 800089f8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	33a98993          	addi	s3,s3,826 # 80010c38 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0f248493          	addi	s1,s1,242 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0f290913          	addi	s2,s2,242 # 80008a00 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a14080e7          	jalr	-1516(ra) # 80002332 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	30448493          	addi	s1,s1,772 # 80010c38 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	0ae7bc23          	sd	a4,184(a5) # 80008a00 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	27e48493          	addi	s1,s1,638 # 80010c38 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	6a478793          	addi	a5,a5,1700 # 800220a0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	25490913          	addi	s2,s2,596 # 80010c70 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1b650513          	addi	a0,a0,438 # 80010c70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	5d250513          	addi	a0,a0,1490 # 800220a0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	18048493          	addi	s1,s1,384 # 80010c70 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	16850513          	addi	a0,a0,360 # 80010c70 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	13c50513          	addi	a0,a0,316 # 80010c70 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	ff8080e7          	jalr	-8(ra) # 80001b68 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	fc6080e7          	jalr	-58(ra) # 80001b68 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	fba080e7          	jalr	-70(ra) # 80001b68 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	fa2080e7          	jalr	-94(ra) # 80001b68 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	f62080e7          	jalr	-158(ra) # 80001b68 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f36080e7          	jalr	-202(ra) # 80001b68 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcf61>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	cd8080e7          	jalr	-808(ra) # 80001b58 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b8070713          	addi	a4,a4,-1152 # 80008a08 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	cbc080e7          	jalr	-836(ra) # 80001b58 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	bb0080e7          	jalr	-1104(ra) # 80002a6e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	1ea080e7          	jalr	490(ra) # 800060b0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	342080e7          	jalr	834(ra) # 80002210 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	b48080e7          	jalr	-1208(ra) # 80001a76 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	b10080e7          	jalr	-1264(ra) # 80002a46 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	b30080e7          	jalr	-1232(ra) # 80002a6e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	154080e7          	jalr	340(ra) # 8000609a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	162080e7          	jalr	354(ra) # 800060b0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	304080e7          	jalr	772(ra) # 8000325a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	9a4080e7          	jalr	-1628(ra) # 80003902 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	94a080e7          	jalr	-1718(ra) # 800048b0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	24a080e7          	jalr	586(ra) # 800061b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	ee6080e7          	jalr	-282(ra) # 80001e5c <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a8f72223          	sw	a5,-1404(a4) # 80008a08 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a787b783          	ld	a5,-1416(a5) # 80008a10 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcf57>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	7b2080e7          	jalr	1970(ra) # 800019e0 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	7aa7be23          	sd	a0,1980(a5) # 80008a10 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcf60>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <mlfq_scheduler>:
#define LOW 1
#define PRIORITY_HIGH 5 // The high priority queue's time, before going to the lower priority
#define PRIORITY_LOW 15 // The low priority queue's time, before boosted up to high priority

void mlfq_scheduler(void)
{
    80001836:	711d                	addi	sp,sp,-96
    80001838:	ec86                	sd	ra,88(sp)
    8000183a:	e8a2                	sd	s0,80(sp)
    8000183c:	e4a6                	sd	s1,72(sp)
    8000183e:	e0ca                	sd	s2,64(sp)
    80001840:	fc4e                	sd	s3,56(sp)
    80001842:	f852                	sd	s4,48(sp)
    80001844:	f456                	sd	s5,40(sp)
    80001846:	f05a                	sd	s6,32(sp)
    80001848:	ec5e                	sd	s7,24(sp)
    8000184a:	e862                	sd	s8,16(sp)
    8000184c:	e466                	sd	s9,8(sp)
    8000184e:	e06a                	sd	s10,0(sp)
    80001850:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80001852:	8792                	mv	a5,tp
    int id = r_tp();
    80001854:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    80001856:	0000fc17          	auipc	s8,0xf
    8000185a:	43ac0c13          	addi	s8,s8,1082 # 80010c90 <cpus>
    8000185e:	00779713          	slli	a4,a5,0x7
    80001862:	00ec06b3          	add	a3,s8,a4
    80001866:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdcf60>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000186a:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000186e:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001872:	10069073          	csrw	sstatus,a3
            acquire(&p->lock);
            if (p->state == RUNNABLE && p->priority == priority) // If the process is runnable and it has the right priority (in the right scheduler state) it can continue
            {
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context); // When switch is called we change one process to the other.
    80001876:	0721                	addi	a4,a4,8
    80001878:	9c3a                	add	s8,s8,a4
    for (int priority = HIGH; priority <= LOW; priority++)
    8000187a:	4c81                	li	s9,0
            if (p->state == RUNNABLE && p->priority == priority) // If the process is runnable and it has the right priority (in the right scheduler state) it can continue
    8000187c:	4a0d                	li	s4,3
                p->state = RUNNING;
    8000187e:	4b91                	li	s7,4
                c->proc = p;
    80001880:	079e                	slli	a5,a5,0x7
    80001882:	0000fb17          	auipc	s6,0xf
    80001886:	40eb0b13          	addi	s6,s6,1038 # 80010c90 <cpus>
    8000188a:	9b3e                	add	s6,s6,a5
        for (p = proc; p < &proc[NPROC]; p++)
    8000188c:	00015997          	auipc	s3,0x15
    80001890:	43498993          	addi	s3,s3,1076 # 80016cc0 <tickslock>
    80001894:	a885                	j	80001904 <mlfq_scheduler+0xce>

                if (p->priority == HIGH && p->timeUsed >= PRIORITY_HIGH) // Here it will check if the process has used its time slice aka (5) and if it has it will change the priority to low
                {
                    p->priority = LOW; // The process will  change its priority to low (the low queue)
                }
                else if (p->priority == LOW && p->timeUsed >= PRIORITY_LOW) // Here it will check if the process has used its time slice aka (15) and if it has it will change the priority to high
    80001896:	01a79863          	bne	a5,s10,800018a6 <mlfq_scheduler+0x70>
    8000189a:	5098                	lw	a4,32(s1)
    8000189c:	47b9                	li	a5,14
    8000189e:	00e7d463          	bge	a5,a4,800018a6 <mlfq_scheduler+0x70>
                {
                    p->priority = HIGH; // Here we are boosted back to high priority
    800018a2:	0004ae23          	sw	zero,28(s1)
                }
                p->timeUsed = 0; // Reset time slice usage for upcoming scheduling round, so we are ready for the next round
    800018a6:	0204a023          	sw	zero,32(s1)
                c->proc = 0;
    800018aa:	000b3023          	sd	zero,0(s6)
            }
            release(&p->lock); // Open the lock again
    800018ae:	8526                	mv	a0,s1
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	3da080e7          	jalr	986(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800018b8:	17048493          	addi	s1,s1,368
    800018bc:	05348063          	beq	s1,s3,800018fc <mlfq_scheduler+0xc6>
            acquire(&p->lock);
    800018c0:	8526                	mv	a0,s1
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	314080e7          	jalr	788(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE && p->priority == priority) // If the process is runnable and it has the right priority (in the right scheduler state) it can continue
    800018ca:	4c9c                	lw	a5,24(s1)
    800018cc:	ff4791e3          	bne	a5,s4,800018ae <mlfq_scheduler+0x78>
    800018d0:	4cdc                	lw	a5,28(s1)
    800018d2:	fd579ee3          	bne	a5,s5,800018ae <mlfq_scheduler+0x78>
                p->state = RUNNING;
    800018d6:	0174ac23          	sw	s7,24(s1)
                c->proc = p;
    800018da:	009b3023          	sd	s1,0(s6)
                swtch(&c->context, &p->context); // When switch is called we change one process to the other.
    800018de:	06848593          	addi	a1,s1,104
    800018e2:	8562                	mv	a0,s8
    800018e4:	00001097          	auipc	ra,0x1
    800018e8:	0f8080e7          	jalr	248(ra) # 800029dc <swtch>
                if (p->priority == HIGH && p->timeUsed >= PRIORITY_HIGH) // Here it will check if the process has used its time slice aka (5) and if it has it will change the priority to low
    800018ec:	4cdc                	lw	a5,28(s1)
    800018ee:	f7c5                	bnez	a5,80001896 <mlfq_scheduler+0x60>
    800018f0:	509c                	lw	a5,32(s1)
    800018f2:	fafbdae3          	bge	s7,a5,800018a6 <mlfq_scheduler+0x70>
                    p->priority = LOW; // The process will  change its priority to low (the low queue)
    800018f6:	01a4ae23          	sw	s10,28(s1)
    800018fa:	b775                	j	800018a6 <mlfq_scheduler+0x70>
    for (int priority = HIGH; priority <= LOW; priority++)
    800018fc:	2c85                	addiw	s9,s9,1
    800018fe:	4789                	li	a5,2
    80001900:	00fc8a63          	beq	s9,a5,80001914 <mlfq_scheduler+0xde>
        for (p = proc; p < &proc[NPROC]; p++)
    80001904:	0000f497          	auipc	s1,0xf
    80001908:	7bc48493          	addi	s1,s1,1980 # 800110c0 <proc>
            if (p->state == RUNNABLE && p->priority == priority) // If the process is runnable and it has the right priority (in the right scheduler state) it can continue
    8000190c:	000c8a9b          	sext.w	s5,s9
                else if (p->priority == LOW && p->timeUsed >= PRIORITY_LOW) // Here it will check if the process has used its time slice aka (15) and if it has it will change the priority to high
    80001910:	4d05                	li	s10,1
    80001912:	b77d                	j	800018c0 <mlfq_scheduler+0x8a>
        }
    }
}
    80001914:	60e6                	ld	ra,88(sp)
    80001916:	6446                	ld	s0,80(sp)
    80001918:	64a6                	ld	s1,72(sp)
    8000191a:	6906                	ld	s2,64(sp)
    8000191c:	79e2                	ld	s3,56(sp)
    8000191e:	7a42                	ld	s4,48(sp)
    80001920:	7aa2                	ld	s5,40(sp)
    80001922:	7b02                	ld	s6,32(sp)
    80001924:	6be2                	ld	s7,24(sp)
    80001926:	6c42                	ld	s8,16(sp)
    80001928:	6ca2                	ld	s9,8(sp)
    8000192a:	6d02                	ld	s10,0(sp)
    8000192c:	6125                	addi	sp,sp,96
    8000192e:	8082                	ret

0000000080001930 <rr_scheduler>:

void rr_scheduler(void)
{
    80001930:	7139                	addi	sp,sp,-64
    80001932:	fc06                	sd	ra,56(sp)
    80001934:	f822                	sd	s0,48(sp)
    80001936:	f426                	sd	s1,40(sp)
    80001938:	f04a                	sd	s2,32(sp)
    8000193a:	ec4e                	sd	s3,24(sp)
    8000193c:	e852                	sd	s4,16(sp)
    8000193e:	e456                	sd	s5,8(sp)
    80001940:	e05a                	sd	s6,0(sp)
    80001942:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80001944:	8792                	mv	a5,tp
    int id = r_tp();
    80001946:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001948:	0000fa97          	auipc	s5,0xf
    8000194c:	348a8a93          	addi	s5,s5,840 # 80010c90 <cpus>
    80001950:	00779713          	slli	a4,a5,0x7
    80001954:	00ea86b3          	add	a3,s5,a4
    80001958:	0006b023          	sd	zero,0(a3)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000195c:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001960:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001964:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001968:	0721                	addi	a4,a4,8
    8000196a:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000196c:	0000f497          	auipc	s1,0xf
    80001970:	75448493          	addi	s1,s1,1876 # 800110c0 <proc>
        if (p->state == RUNNABLE)
    80001974:	498d                	li	s3,3
            p->state = RUNNING;
    80001976:	4b11                	li	s6,4
            c->proc = p;
    80001978:	079e                	slli	a5,a5,0x7
    8000197a:	0000fa17          	auipc	s4,0xf
    8000197e:	316a0a13          	addi	s4,s4,790 # 80010c90 <cpus>
    80001982:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001984:	00015917          	auipc	s2,0x15
    80001988:	33c90913          	addi	s2,s2,828 # 80016cc0 <tickslock>
    8000198c:	a811                	j	800019a0 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    8000198e:	8526                	mv	a0,s1
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	2fa080e7          	jalr	762(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001998:	17048493          	addi	s1,s1,368
    8000199c:	03248863          	beq	s1,s2,800019cc <rr_scheduler+0x9c>
        acquire(&p->lock);
    800019a0:	8526                	mv	a0,s1
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	234080e7          	jalr	564(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800019aa:	4c9c                	lw	a5,24(s1)
    800019ac:	ff3791e3          	bne	a5,s3,8000198e <rr_scheduler+0x5e>
            p->state = RUNNING;
    800019b0:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800019b4:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800019b8:	06848593          	addi	a1,s1,104
    800019bc:	8556                	mv	a0,s5
    800019be:	00001097          	auipc	ra,0x1
    800019c2:	01e080e7          	jalr	30(ra) # 800029dc <swtch>
            c->proc = 0;
    800019c6:	000a3023          	sd	zero,0(s4)
    800019ca:	b7d1                	j	8000198e <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800019cc:	70e2                	ld	ra,56(sp)
    800019ce:	7442                	ld	s0,48(sp)
    800019d0:	74a2                	ld	s1,40(sp)
    800019d2:	7902                	ld	s2,32(sp)
    800019d4:	69e2                	ld	s3,24(sp)
    800019d6:	6a42                	ld	s4,16(sp)
    800019d8:	6aa2                	ld	s5,8(sp)
    800019da:	6b02                	ld	s6,0(sp)
    800019dc:	6121                	addi	sp,sp,64
    800019de:	8082                	ret

00000000800019e0 <proc_mapstacks>:
{
    800019e0:	7139                	addi	sp,sp,-64
    800019e2:	fc06                	sd	ra,56(sp)
    800019e4:	f822                	sd	s0,48(sp)
    800019e6:	f426                	sd	s1,40(sp)
    800019e8:	f04a                	sd	s2,32(sp)
    800019ea:	ec4e                	sd	s3,24(sp)
    800019ec:	e852                	sd	s4,16(sp)
    800019ee:	e456                	sd	s5,8(sp)
    800019f0:	e05a                	sd	s6,0(sp)
    800019f2:	0080                	addi	s0,sp,64
    800019f4:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800019f6:	0000f497          	auipc	s1,0xf
    800019fa:	6ca48493          	addi	s1,s1,1738 # 800110c0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    800019fe:	8b26                	mv	s6,s1
    80001a00:	00006a97          	auipc	s5,0x6
    80001a04:	600a8a93          	addi	s5,s5,1536 # 80008000 <etext>
    80001a08:	04000937          	lui	s2,0x4000
    80001a0c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a0e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a10:	00015a17          	auipc	s4,0x15
    80001a14:	2b0a0a13          	addi	s4,s4,688 # 80016cc0 <tickslock>
        char *pa = kalloc();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	0ce080e7          	jalr	206(ra) # 80000ae6 <kalloc>
    80001a20:	862a                	mv	a2,a0
        if (pa == 0)
    80001a22:	c131                	beqz	a0,80001a66 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a24:	416485b3          	sub	a1,s1,s6
    80001a28:	8591                	srai	a1,a1,0x4
    80001a2a:	000ab783          	ld	a5,0(s5)
    80001a2e:	02f585b3          	mul	a1,a1,a5
    80001a32:	2585                	addiw	a1,a1,1
    80001a34:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a38:	4719                	li	a4,6
    80001a3a:	6685                	lui	a3,0x1
    80001a3c:	40b905b3          	sub	a1,s2,a1
    80001a40:	854e                	mv	a0,s3
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	6fc080e7          	jalr	1788(ra) # 8000113e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a4a:	17048493          	addi	s1,s1,368
    80001a4e:	fd4495e3          	bne	s1,s4,80001a18 <proc_mapstacks+0x38>
}
    80001a52:	70e2                	ld	ra,56(sp)
    80001a54:	7442                	ld	s0,48(sp)
    80001a56:	74a2                	ld	s1,40(sp)
    80001a58:	7902                	ld	s2,32(sp)
    80001a5a:	69e2                	ld	s3,24(sp)
    80001a5c:	6a42                	ld	s4,16(sp)
    80001a5e:	6aa2                	ld	s5,8(sp)
    80001a60:	6b02                	ld	s6,0(sp)
    80001a62:	6121                	addi	sp,sp,64
    80001a64:	8082                	ret
            panic("kalloc");
    80001a66:	00006517          	auipc	a0,0x6
    80001a6a:	77250513          	addi	a0,a0,1906 # 800081d8 <digits+0x198>
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	ad2080e7          	jalr	-1326(ra) # 80000540 <panic>

0000000080001a76 <procinit>:
{
    80001a76:	7139                	addi	sp,sp,-64
    80001a78:	fc06                	sd	ra,56(sp)
    80001a7a:	f822                	sd	s0,48(sp)
    80001a7c:	f426                	sd	s1,40(sp)
    80001a7e:	f04a                	sd	s2,32(sp)
    80001a80:	ec4e                	sd	s3,24(sp)
    80001a82:	e852                	sd	s4,16(sp)
    80001a84:	e456                	sd	s5,8(sp)
    80001a86:	e05a                	sd	s6,0(sp)
    80001a88:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001a8a:	00006597          	auipc	a1,0x6
    80001a8e:	75658593          	addi	a1,a1,1878 # 800081e0 <digits+0x1a0>
    80001a92:	0000f517          	auipc	a0,0xf
    80001a96:	5fe50513          	addi	a0,a0,1534 # 80011090 <pid_lock>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	0ac080e7          	jalr	172(ra) # 80000b46 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001aa2:	00006597          	auipc	a1,0x6
    80001aa6:	74658593          	addi	a1,a1,1862 # 800081e8 <digits+0x1a8>
    80001aaa:	0000f517          	auipc	a0,0xf
    80001aae:	5fe50513          	addi	a0,a0,1534 # 800110a8 <wait_lock>
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	094080e7          	jalr	148(ra) # 80000b46 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aba:	0000f497          	auipc	s1,0xf
    80001abe:	60648493          	addi	s1,s1,1542 # 800110c0 <proc>
        initlock(&p->lock, "proc");
    80001ac2:	00006b17          	auipc	s6,0x6
    80001ac6:	736b0b13          	addi	s6,s6,1846 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    80001aca:	8aa6                	mv	s5,s1
    80001acc:	00006a17          	auipc	s4,0x6
    80001ad0:	534a0a13          	addi	s4,s4,1332 # 80008000 <etext>
    80001ad4:	04000937          	lui	s2,0x4000
    80001ad8:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001adc:	00015997          	auipc	s3,0x15
    80001ae0:	1e498993          	addi	s3,s3,484 # 80016cc0 <tickslock>
        initlock(&p->lock, "proc");
    80001ae4:	85da                	mv	a1,s6
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	05e080e7          	jalr	94(ra) # 80000b46 <initlock>
        p->state = UNUSED;
    80001af0:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001af4:	415487b3          	sub	a5,s1,s5
    80001af8:	8791                	srai	a5,a5,0x4
    80001afa:	000a3703          	ld	a4,0(s4)
    80001afe:	02e787b3          	mul	a5,a5,a4
    80001b02:	2785                	addiw	a5,a5,1
    80001b04:	00d7979b          	slliw	a5,a5,0xd
    80001b08:	40f907b3          	sub	a5,s2,a5
    80001b0c:	e4bc                	sd	a5,72(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b0e:	17048493          	addi	s1,s1,368
    80001b12:	fd3499e3          	bne	s1,s3,80001ae4 <procinit+0x6e>
}
    80001b16:	70e2                	ld	ra,56(sp)
    80001b18:	7442                	ld	s0,48(sp)
    80001b1a:	74a2                	ld	s1,40(sp)
    80001b1c:	7902                	ld	s2,32(sp)
    80001b1e:	69e2                	ld	s3,24(sp)
    80001b20:	6a42                	ld	s4,16(sp)
    80001b22:	6aa2                	ld	s5,8(sp)
    80001b24:	6b02                	ld	s6,0(sp)
    80001b26:	6121                	addi	sp,sp,64
    80001b28:	8082                	ret

0000000080001b2a <copy_array>:
{
    80001b2a:	1141                	addi	sp,sp,-16
    80001b2c:	e422                	sd	s0,8(sp)
    80001b2e:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b30:	02c05163          	blez	a2,80001b52 <copy_array+0x28>
    80001b34:	87aa                	mv	a5,a0
    80001b36:	0505                	addi	a0,a0,1
    80001b38:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001b3a:	1602                	slli	a2,a2,0x20
    80001b3c:	9201                	srli	a2,a2,0x20
    80001b3e:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001b42:	0007c703          	lbu	a4,0(a5)
    80001b46:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b4a:	0785                	addi	a5,a5,1
    80001b4c:	0585                	addi	a1,a1,1
    80001b4e:	fed79ae3          	bne	a5,a3,80001b42 <copy_array+0x18>
}
    80001b52:	6422                	ld	s0,8(sp)
    80001b54:	0141                	addi	sp,sp,16
    80001b56:	8082                	ret

0000000080001b58 <cpuid>:
{
    80001b58:	1141                	addi	sp,sp,-16
    80001b5a:	e422                	sd	s0,8(sp)
    80001b5c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b5e:	8512                	mv	a0,tp
}
    80001b60:	2501                	sext.w	a0,a0
    80001b62:	6422                	ld	s0,8(sp)
    80001b64:	0141                	addi	sp,sp,16
    80001b66:	8082                	ret

0000000080001b68 <mycpu>:
{
    80001b68:	1141                	addi	sp,sp,-16
    80001b6a:	e422                	sd	s0,8(sp)
    80001b6c:	0800                	addi	s0,sp,16
    80001b6e:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b70:	2781                	sext.w	a5,a5
    80001b72:	079e                	slli	a5,a5,0x7
}
    80001b74:	0000f517          	auipc	a0,0xf
    80001b78:	11c50513          	addi	a0,a0,284 # 80010c90 <cpus>
    80001b7c:	953e                	add	a0,a0,a5
    80001b7e:	6422                	ld	s0,8(sp)
    80001b80:	0141                	addi	sp,sp,16
    80001b82:	8082                	ret

0000000080001b84 <myproc>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	1000                	addi	s0,sp,32
    push_off();
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	ffc080e7          	jalr	-4(ra) # 80000b8a <push_off>
    80001b96:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001b98:	2781                	sext.w	a5,a5
    80001b9a:	079e                	slli	a5,a5,0x7
    80001b9c:	0000f717          	auipc	a4,0xf
    80001ba0:	0f470713          	addi	a4,a4,244 # 80010c90 <cpus>
    80001ba4:	97ba                	add	a5,a5,a4
    80001ba6:	6384                	ld	s1,0(a5)
    pop_off();
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	082080e7          	jalr	130(ra) # 80000c2a <pop_off>
}
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	60e2                	ld	ra,24(sp)
    80001bb4:	6442                	ld	s0,16(sp)
    80001bb6:	64a2                	ld	s1,8(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bbc:	1141                	addi	sp,sp,-16
    80001bbe:	e406                	sd	ra,8(sp)
    80001bc0:	e022                	sd	s0,0(sp)
    80001bc2:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	fc0080e7          	jalr	-64(ra) # 80001b84 <myproc>
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0be080e7          	jalr	190(ra) # 80000c8a <release>

    if (first)
    80001bd4:	00007797          	auipc	a5,0x7
    80001bd8:	d5c7a783          	lw	a5,-676(a5) # 80008930 <first.1>
    80001bdc:	eb89                	bnez	a5,80001bee <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001bde:	00001097          	auipc	ra,0x1
    80001be2:	ea8080e7          	jalr	-344(ra) # 80002a86 <usertrapret>
}
    80001be6:	60a2                	ld	ra,8(sp)
    80001be8:	6402                	ld	s0,0(sp)
    80001bea:	0141                	addi	sp,sp,16
    80001bec:	8082                	ret
        first = 0;
    80001bee:	00007797          	auipc	a5,0x7
    80001bf2:	d407a123          	sw	zero,-702(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001bf6:	4505                	li	a0,1
    80001bf8:	00002097          	auipc	ra,0x2
    80001bfc:	c8a080e7          	jalr	-886(ra) # 80003882 <fsinit>
    80001c00:	bff9                	j	80001bde <forkret+0x22>

0000000080001c02 <allocpid>:
{
    80001c02:	1101                	addi	sp,sp,-32
    80001c04:	ec06                	sd	ra,24(sp)
    80001c06:	e822                	sd	s0,16(sp)
    80001c08:	e426                	sd	s1,8(sp)
    80001c0a:	e04a                	sd	s2,0(sp)
    80001c0c:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c0e:	0000f917          	auipc	s2,0xf
    80001c12:	48290913          	addi	s2,s2,1154 # 80011090 <pid_lock>
    80001c16:	854a                	mv	a0,s2
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	fbe080e7          	jalr	-66(ra) # 80000bd6 <acquire>
    pid = nextpid;
    80001c20:	00007797          	auipc	a5,0x7
    80001c24:	d2078793          	addi	a5,a5,-736 # 80008940 <nextpid>
    80001c28:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c2a:	0014871b          	addiw	a4,s1,1
    80001c2e:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c30:	854a                	mv	a0,s2
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	058080e7          	jalr	88(ra) # 80000c8a <release>
}
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6902                	ld	s2,0(sp)
    80001c44:	6105                	addi	sp,sp,32
    80001c46:	8082                	ret

0000000080001c48 <proc_pagetable>:
{
    80001c48:	1101                	addi	sp,sp,-32
    80001c4a:	ec06                	sd	ra,24(sp)
    80001c4c:	e822                	sd	s0,16(sp)
    80001c4e:	e426                	sd	s1,8(sp)
    80001c50:	e04a                	sd	s2,0(sp)
    80001c52:	1000                	addi	s0,sp,32
    80001c54:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	6d2080e7          	jalr	1746(ra) # 80001328 <uvmcreate>
    80001c5e:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c60:	c121                	beqz	a0,80001ca0 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c62:	4729                	li	a4,10
    80001c64:	00005697          	auipc	a3,0x5
    80001c68:	39c68693          	addi	a3,a3,924 # 80007000 <_trampoline>
    80001c6c:	6605                	lui	a2,0x1
    80001c6e:	040005b7          	lui	a1,0x4000
    80001c72:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c74:	05b2                	slli	a1,a1,0xc
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	428080e7          	jalr	1064(ra) # 8000109e <mappages>
    80001c7e:	02054863          	bltz	a0,80001cae <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c82:	4719                	li	a4,6
    80001c84:	06093683          	ld	a3,96(s2)
    80001c88:	6605                	lui	a2,0x1
    80001c8a:	020005b7          	lui	a1,0x2000
    80001c8e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c90:	05b6                	slli	a1,a1,0xd
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	40a080e7          	jalr	1034(ra) # 8000109e <mappages>
    80001c9c:	02054163          	bltz	a0,80001cbe <proc_pagetable+0x76>
}
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6902                	ld	s2,0(sp)
    80001caa:	6105                	addi	sp,sp,32
    80001cac:	8082                	ret
        uvmfree(pagetable, 0);
    80001cae:	4581                	li	a1,0
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	87c080e7          	jalr	-1924(ra) # 8000152e <uvmfree>
        return 0;
    80001cba:	4481                	li	s1,0
    80001cbc:	b7d5                	j	80001ca0 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cbe:	4681                	li	a3,0
    80001cc0:	4605                	li	a2,1
    80001cc2:	040005b7          	lui	a1,0x4000
    80001cc6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cc8:	05b2                	slli	a1,a1,0xc
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	598080e7          	jalr	1432(ra) # 80001264 <uvmunmap>
        uvmfree(pagetable, 0);
    80001cd4:	4581                	li	a1,0
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	856080e7          	jalr	-1962(ra) # 8000152e <uvmfree>
        return 0;
    80001ce0:	4481                	li	s1,0
    80001ce2:	bf7d                	j	80001ca0 <proc_pagetable+0x58>

0000000080001ce4 <proc_freepagetable>:
{
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	e04a                	sd	s2,0(sp)
    80001cee:	1000                	addi	s0,sp,32
    80001cf0:	84aa                	mv	s1,a0
    80001cf2:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf4:	4681                	li	a3,0
    80001cf6:	4605                	li	a2,1
    80001cf8:	040005b7          	lui	a1,0x4000
    80001cfc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cfe:	05b2                	slli	a1,a1,0xc
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	564080e7          	jalr	1380(ra) # 80001264 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d08:	4681                	li	a3,0
    80001d0a:	4605                	li	a2,1
    80001d0c:	020005b7          	lui	a1,0x2000
    80001d10:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d12:	05b6                	slli	a1,a1,0xd
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	54e080e7          	jalr	1358(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d1e:	85ca                	mv	a1,s2
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	80c080e7          	jalr	-2036(ra) # 8000152e <uvmfree>
}
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6902                	ld	s2,0(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <freeproc>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d42:	7128                	ld	a0,96(a0)
    80001d44:	c509                	beqz	a0,80001d4e <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	ca2080e7          	jalr	-862(ra) # 800009e8 <kfree>
    p->trapframe = 0;
    80001d4e:	0604b023          	sd	zero,96(s1)
    if (p->pagetable)
    80001d52:	6ca8                	ld	a0,88(s1)
    80001d54:	c511                	beqz	a0,80001d60 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d56:	68ac                	ld	a1,80(s1)
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	f8c080e7          	jalr	-116(ra) # 80001ce4 <proc_freepagetable>
    p->pagetable = 0;
    80001d60:	0404bc23          	sd	zero,88(s1)
    p->sz = 0;
    80001d64:	0404b823          	sd	zero,80(s1)
    p->pid = 0;
    80001d68:	0204ac23          	sw	zero,56(s1)
    p->parent = 0;
    80001d6c:	0404b023          	sd	zero,64(s1)
    p->name[0] = 0;
    80001d70:	16048023          	sb	zero,352(s1)
    p->chan = 0;
    80001d74:	0204b423          	sd	zero,40(s1)
    p->killed = 0;
    80001d78:	0204a823          	sw	zero,48(s1)
    p->xstate = 0;
    80001d7c:	0204aa23          	sw	zero,52(s1)
    p->state = UNUSED;
    80001d80:	0004ac23          	sw	zero,24(s1)
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <allocproc>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001d9a:	0000f497          	auipc	s1,0xf
    80001d9e:	32648493          	addi	s1,s1,806 # 800110c0 <proc>
    80001da2:	00015917          	auipc	s2,0x15
    80001da6:	f1e90913          	addi	s2,s2,-226 # 80016cc0 <tickslock>
        acquire(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	e2a080e7          	jalr	-470(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001db4:	4c9c                	lw	a5,24(s1)
    80001db6:	cf81                	beqz	a5,80001dce <allocproc+0x40>
            release(&p->lock);
    80001db8:	8526                	mv	a0,s1
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	ed0080e7          	jalr	-304(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001dc2:	17048493          	addi	s1,s1,368
    80001dc6:	ff2492e3          	bne	s1,s2,80001daa <allocproc+0x1c>
    return 0;
    80001dca:	4481                	li	s1,0
    80001dcc:	a889                	j	80001e1e <allocproc+0x90>
    p->pid = allocpid();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	e34080e7          	jalr	-460(ra) # 80001c02 <allocpid>
    80001dd6:	dc88                	sw	a0,56(s1)
    p->state = USED;
    80001dd8:	4785                	li	a5,1
    80001dda:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	d0a080e7          	jalr	-758(ra) # 80000ae6 <kalloc>
    80001de4:	892a                	mv	s2,a0
    80001de6:	f0a8                	sd	a0,96(s1)
    80001de8:	c131                	beqz	a0,80001e2c <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001dea:	8526                	mv	a0,s1
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	e5c080e7          	jalr	-420(ra) # 80001c48 <proc_pagetable>
    80001df4:	892a                	mv	s2,a0
    80001df6:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    80001df8:	c531                	beqz	a0,80001e44 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001dfa:	07000613          	li	a2,112
    80001dfe:	4581                	li	a1,0
    80001e00:	06848513          	addi	a0,s1,104
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	ece080e7          	jalr	-306(ra) # 80000cd2 <memset>
    p->context.ra = (uint64)forkret;
    80001e0c:	00000797          	auipc	a5,0x0
    80001e10:	db078793          	addi	a5,a5,-592 # 80001bbc <forkret>
    80001e14:	f4bc                	sd	a5,104(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e16:	64bc                	ld	a5,72(s1)
    80001e18:	6705                	lui	a4,0x1
    80001e1a:	97ba                	add	a5,a5,a4
    80001e1c:	f8bc                	sd	a5,112(s1)
}
    80001e1e:	8526                	mv	a0,s1
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6902                	ld	s2,0(sp)
    80001e28:	6105                	addi	sp,sp,32
    80001e2a:	8082                	ret
        freeproc(p);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	f08080e7          	jalr	-248(ra) # 80001d36 <freeproc>
        release(&p->lock);
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e52080e7          	jalr	-430(ra) # 80000c8a <release>
        return 0;
    80001e40:	84ca                	mv	s1,s2
    80001e42:	bff1                	j	80001e1e <allocproc+0x90>
        freeproc(p);
    80001e44:	8526                	mv	a0,s1
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	ef0080e7          	jalr	-272(ra) # 80001d36 <freeproc>
        release(&p->lock);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e3a080e7          	jalr	-454(ra) # 80000c8a <release>
        return 0;
    80001e58:	84ca                	mv	s1,s2
    80001e5a:	b7d1                	j	80001e1e <allocproc+0x90>

0000000080001e5c <userinit>:
{
    80001e5c:	1101                	addi	sp,sp,-32
    80001e5e:	ec06                	sd	ra,24(sp)
    80001e60:	e822                	sd	s0,16(sp)
    80001e62:	e426                	sd	s1,8(sp)
    80001e64:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	f28080e7          	jalr	-216(ra) # 80001d8e <allocproc>
    80001e6e:	84aa                	mv	s1,a0
    initproc = p;
    80001e70:	00007797          	auipc	a5,0x7
    80001e74:	baa7b423          	sd	a0,-1112(a5) # 80008a18 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e78:	03400613          	li	a2,52
    80001e7c:	00007597          	auipc	a1,0x7
    80001e80:	ad458593          	addi	a1,a1,-1324 # 80008950 <initcode>
    80001e84:	6d28                	ld	a0,88(a0)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	4d0080e7          	jalr	1232(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001e8e:	6785                	lui	a5,0x1
    80001e90:	e8bc                	sd	a5,80(s1)
    p->trapframe->epc = 0;     // user program counter
    80001e92:	70b8                	ld	a4,96(s1)
    80001e94:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001e98:	70b8                	ld	a4,96(s1)
    80001e9a:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9c:	4641                	li	a2,16
    80001e9e:	00006597          	auipc	a1,0x6
    80001ea2:	36258593          	addi	a1,a1,866 # 80008200 <digits+0x1c0>
    80001ea6:	16048513          	addi	a0,s1,352
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	f72080e7          	jalr	-142(ra) # 80000e1c <safestrcpy>
    p->cwd = namei("/");
    80001eb2:	00006517          	auipc	a0,0x6
    80001eb6:	35e50513          	addi	a0,a0,862 # 80008210 <digits+0x1d0>
    80001eba:	00002097          	auipc	ra,0x2
    80001ebe:	3f2080e7          	jalr	1010(ra) # 800042ac <namei>
    80001ec2:	14a4bc23          	sd	a0,344(s1)
    p->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dbe080e7          	jalr	-578(ra) # 80000c8a <release>
}
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret

0000000080001ede <growproc>:
{
    80001ede:	1101                	addi	sp,sp,-32
    80001ee0:	ec06                	sd	ra,24(sp)
    80001ee2:	e822                	sd	s0,16(sp)
    80001ee4:	e426                	sd	s1,8(sp)
    80001ee6:	e04a                	sd	s2,0(sp)
    80001ee8:	1000                	addi	s0,sp,32
    80001eea:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	c98080e7          	jalr	-872(ra) # 80001b84 <myproc>
    80001ef4:	84aa                	mv	s1,a0
    sz = p->sz;
    80001ef6:	692c                	ld	a1,80(a0)
    if (n > 0)
    80001ef8:	01204c63          	bgtz	s2,80001f10 <growproc+0x32>
    else if (n < 0)
    80001efc:	02094663          	bltz	s2,80001f28 <growproc+0x4a>
    p->sz = sz;
    80001f00:	e8ac                	sd	a1,80(s1)
    return 0;
    80001f02:	4501                	li	a0,0
}
    80001f04:	60e2                	ld	ra,24(sp)
    80001f06:	6442                	ld	s0,16(sp)
    80001f08:	64a2                	ld	s1,8(sp)
    80001f0a:	6902                	ld	s2,0(sp)
    80001f0c:	6105                	addi	sp,sp,32
    80001f0e:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f10:	4691                	li	a3,4
    80001f12:	00b90633          	add	a2,s2,a1
    80001f16:	6d28                	ld	a0,88(a0)
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	4f8080e7          	jalr	1272(ra) # 80001410 <uvmalloc>
    80001f20:	85aa                	mv	a1,a0
    80001f22:	fd79                	bnez	a0,80001f00 <growproc+0x22>
            return -1;
    80001f24:	557d                	li	a0,-1
    80001f26:	bff9                	j	80001f04 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f28:	00b90633          	add	a2,s2,a1
    80001f2c:	6d28                	ld	a0,88(a0)
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	49a080e7          	jalr	1178(ra) # 800013c8 <uvmdealloc>
    80001f36:	85aa                	mv	a1,a0
    80001f38:	b7e1                	j	80001f00 <growproc+0x22>

0000000080001f3a <ps>:
{
    80001f3a:	715d                	addi	sp,sp,-80
    80001f3c:	e486                	sd	ra,72(sp)
    80001f3e:	e0a2                	sd	s0,64(sp)
    80001f40:	fc26                	sd	s1,56(sp)
    80001f42:	f84a                	sd	s2,48(sp)
    80001f44:	f44e                	sd	s3,40(sp)
    80001f46:	f052                	sd	s4,32(sp)
    80001f48:	ec56                	sd	s5,24(sp)
    80001f4a:	e85a                	sd	s6,16(sp)
    80001f4c:	e45e                	sd	s7,8(sp)
    80001f4e:	e062                	sd	s8,0(sp)
    80001f50:	0880                	addi	s0,sp,80
    80001f52:	84aa                	mv	s1,a0
    80001f54:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	c2e080e7          	jalr	-978(ra) # 80001b84 <myproc>
        return result;
    80001f5e:	4901                	li	s2,0
    if (count == 0)
    80001f60:	0c0b8563          	beqz	s7,8000202a <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80001f64:	05053b03          	ld	s6,80(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f68:	003b951b          	slliw	a0,s7,0x3
    80001f6c:	0175053b          	addw	a0,a0,s7
    80001f70:	0025151b          	slliw	a0,a0,0x2
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	f6a080e7          	jalr	-150(ra) # 80001ede <growproc>
    80001f7c:	12054f63          	bltz	a0,800020ba <ps+0x180>
    struct user_proc loc_result[count];
    80001f80:	003b9a13          	slli	s4,s7,0x3
    80001f84:	9a5e                	add	s4,s4,s7
    80001f86:	0a0a                	slli	s4,s4,0x2
    80001f88:	00fa0793          	addi	a5,s4,15
    80001f8c:	8391                	srli	a5,a5,0x4
    80001f8e:	0792                	slli	a5,a5,0x4
    80001f90:	40f10133          	sub	sp,sp,a5
    80001f94:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80001f96:	17000793          	li	a5,368
    80001f9a:	02f484b3          	mul	s1,s1,a5
    80001f9e:	0000f797          	auipc	a5,0xf
    80001fa2:	12278793          	addi	a5,a5,290 # 800110c0 <proc>
    80001fa6:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001fa8:	00015797          	auipc	a5,0x15
    80001fac:	d1878793          	addi	a5,a5,-744 # 80016cc0 <tickslock>
        return result;
    80001fb0:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80001fb2:	06f4fc63          	bgeu	s1,a5,8000202a <ps+0xf0>
    acquire(&wait_lock);
    80001fb6:	0000f517          	auipc	a0,0xf
    80001fba:	0f250513          	addi	a0,a0,242 # 800110a8 <wait_lock>
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c18080e7          	jalr	-1000(ra) # 80000bd6 <acquire>
        if (localCount == count)
    80001fc6:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001fca:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001fcc:	00015c17          	auipc	s8,0x15
    80001fd0:	cf4c0c13          	addi	s8,s8,-780 # 80016cc0 <tickslock>
    80001fd4:	a851                	j	80002068 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    80001fd6:	00399793          	slli	a5,s3,0x3
    80001fda:	97ce                	add	a5,a5,s3
    80001fdc:	078a                	slli	a5,a5,0x2
    80001fde:	97d6                	add	a5,a5,s5
    80001fe0:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	ca4080e7          	jalr	-860(ra) # 80000c8a <release>
    release(&wait_lock);
    80001fee:	0000f517          	auipc	a0,0xf
    80001ff2:	0ba50513          	addi	a0,a0,186 # 800110a8 <wait_lock>
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c94080e7          	jalr	-876(ra) # 80000c8a <release>
    if (localCount < count)
    80001ffe:	0179f963          	bgeu	s3,s7,80002010 <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002002:	00399793          	slli	a5,s3,0x3
    80002006:	97ce                	add	a5,a5,s3
    80002008:	078a                	slli	a5,a5,0x2
    8000200a:	97d6                	add	a5,a5,s5
    8000200c:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80002010:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002012:	00000097          	auipc	ra,0x0
    80002016:	b72080e7          	jalr	-1166(ra) # 80001b84 <myproc>
    8000201a:	86d2                	mv	a3,s4
    8000201c:	8656                	mv	a2,s5
    8000201e:	85da                	mv	a1,s6
    80002020:	6d28                	ld	a0,88(a0)
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	64a080e7          	jalr	1610(ra) # 8000166c <copyout>
}
    8000202a:	854a                	mv	a0,s2
    8000202c:	fb040113          	addi	sp,s0,-80
    80002030:	60a6                	ld	ra,72(sp)
    80002032:	6406                	ld	s0,64(sp)
    80002034:	74e2                	ld	s1,56(sp)
    80002036:	7942                	ld	s2,48(sp)
    80002038:	79a2                	ld	s3,40(sp)
    8000203a:	7a02                	ld	s4,32(sp)
    8000203c:	6ae2                	ld	s5,24(sp)
    8000203e:	6b42                	ld	s6,16(sp)
    80002040:	6ba2                	ld	s7,8(sp)
    80002042:	6c02                	ld	s8,0(sp)
    80002044:	6161                	addi	sp,sp,80
    80002046:	8082                	ret
        release(&p->lock);
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	c40080e7          	jalr	-960(ra) # 80000c8a <release>
        localCount++;
    80002052:	2985                	addiw	s3,s3,1
    80002054:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002058:	17048493          	addi	s1,s1,368
    8000205c:	f984f9e3          	bgeu	s1,s8,80001fee <ps+0xb4>
        if (localCount == count)
    80002060:	02490913          	addi	s2,s2,36
    80002064:	053b8d63          	beq	s7,s3,800020be <ps+0x184>
        acquire(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b6c080e7          	jalr	-1172(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80002072:	4c9c                	lw	a5,24(s1)
    80002074:	d3ad                	beqz	a5,80001fd6 <ps+0x9c>
        loc_result[localCount].state = p->state;
    80002076:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000207a:	589c                	lw	a5,48(s1)
    8000207c:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002080:	58dc                	lw	a5,52(s1)
    80002082:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002086:	5c9c                	lw	a5,56(s1)
    80002088:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000208c:	4641                	li	a2,16
    8000208e:	85ca                	mv	a1,s2
    80002090:	16048513          	addi	a0,s1,352
    80002094:	00000097          	auipc	ra,0x0
    80002098:	a96080e7          	jalr	-1386(ra) # 80001b2a <copy_array>
        if (p->parent != 0) // init
    8000209c:	60a8                	ld	a0,64(s1)
    8000209e:	d54d                	beqz	a0,80002048 <ps+0x10e>
            acquire(&p->parent->lock);
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b36080e7          	jalr	-1226(ra) # 80000bd6 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    800020a8:	60a8                	ld	a0,64(s1)
    800020aa:	5d1c                	lw	a5,56(a0)
    800020ac:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
    800020b8:	bf41                	j	80002048 <ps+0x10e>
        return result;
    800020ba:	4901                	li	s2,0
    800020bc:	b7bd                	j	8000202a <ps+0xf0>
    release(&wait_lock);
    800020be:	0000f517          	auipc	a0,0xf
    800020c2:	fea50513          	addi	a0,a0,-22 # 800110a8 <wait_lock>
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bc4080e7          	jalr	-1084(ra) # 80000c8a <release>
    if (localCount < count)
    800020ce:	b789                	j	80002010 <ps+0xd6>

00000000800020d0 <fork>:
{
    800020d0:	7139                	addi	sp,sp,-64
    800020d2:	fc06                	sd	ra,56(sp)
    800020d4:	f822                	sd	s0,48(sp)
    800020d6:	f426                	sd	s1,40(sp)
    800020d8:	f04a                	sd	s2,32(sp)
    800020da:	ec4e                	sd	s3,24(sp)
    800020dc:	e852                	sd	s4,16(sp)
    800020de:	e456                	sd	s5,8(sp)
    800020e0:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	aa2080e7          	jalr	-1374(ra) # 80001b84 <myproc>
    800020ea:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	ca2080e7          	jalr	-862(ra) # 80001d8e <allocproc>
    800020f4:	10050c63          	beqz	a0,8000220c <fork+0x13c>
    800020f8:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800020fa:	050ab603          	ld	a2,80(s5)
    800020fe:	6d2c                	ld	a1,88(a0)
    80002100:	058ab503          	ld	a0,88(s5)
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	464080e7          	jalr	1124(ra) # 80001568 <uvmcopy>
    8000210c:	04054863          	bltz	a0,8000215c <fork+0x8c>
    np->sz = p->sz;
    80002110:	050ab783          	ld	a5,80(s5)
    80002114:	04fa3823          	sd	a5,80(s4)
    *(np->trapframe) = *(p->trapframe);
    80002118:	060ab683          	ld	a3,96(s5)
    8000211c:	87b6                	mv	a5,a3
    8000211e:	060a3703          	ld	a4,96(s4)
    80002122:	12068693          	addi	a3,a3,288
    80002126:	0007b803          	ld	a6,0(a5)
    8000212a:	6788                	ld	a0,8(a5)
    8000212c:	6b8c                	ld	a1,16(a5)
    8000212e:	6f90                	ld	a2,24(a5)
    80002130:	01073023          	sd	a6,0(a4)
    80002134:	e708                	sd	a0,8(a4)
    80002136:	eb0c                	sd	a1,16(a4)
    80002138:	ef10                	sd	a2,24(a4)
    8000213a:	02078793          	addi	a5,a5,32
    8000213e:	02070713          	addi	a4,a4,32
    80002142:	fed792e3          	bne	a5,a3,80002126 <fork+0x56>
    np->trapframe->a0 = 0;
    80002146:	060a3783          	ld	a5,96(s4)
    8000214a:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000214e:	0d8a8493          	addi	s1,s5,216
    80002152:	0d8a0913          	addi	s2,s4,216
    80002156:	158a8993          	addi	s3,s5,344
    8000215a:	a00d                	j	8000217c <fork+0xac>
        freeproc(np);
    8000215c:	8552                	mv	a0,s4
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	bd8080e7          	jalr	-1064(ra) # 80001d36 <freeproc>
        release(&np->lock);
    80002166:	8552                	mv	a0,s4
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b22080e7          	jalr	-1246(ra) # 80000c8a <release>
        return -1;
    80002170:	597d                	li	s2,-1
    80002172:	a059                	j	800021f8 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002174:	04a1                	addi	s1,s1,8
    80002176:	0921                	addi	s2,s2,8
    80002178:	01348b63          	beq	s1,s3,8000218e <fork+0xbe>
        if (p->ofile[i])
    8000217c:	6088                	ld	a0,0(s1)
    8000217e:	d97d                	beqz	a0,80002174 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002180:	00002097          	auipc	ra,0x2
    80002184:	7c2080e7          	jalr	1986(ra) # 80004942 <filedup>
    80002188:	00a93023          	sd	a0,0(s2)
    8000218c:	b7e5                	j	80002174 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000218e:	158ab503          	ld	a0,344(s5)
    80002192:	00002097          	auipc	ra,0x2
    80002196:	930080e7          	jalr	-1744(ra) # 80003ac2 <idup>
    8000219a:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000219e:	4641                	li	a2,16
    800021a0:	160a8593          	addi	a1,s5,352
    800021a4:	160a0513          	addi	a0,s4,352
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	c74080e7          	jalr	-908(ra) # 80000e1c <safestrcpy>
    pid = np->pid;
    800021b0:	038a2903          	lw	s2,56(s4)
    release(&np->lock);
    800021b4:	8552                	mv	a0,s4
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ad4080e7          	jalr	-1324(ra) # 80000c8a <release>
    acquire(&wait_lock);
    800021be:	0000f497          	auipc	s1,0xf
    800021c2:	eea48493          	addi	s1,s1,-278 # 800110a8 <wait_lock>
    800021c6:	8526                	mv	a0,s1
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	a0e080e7          	jalr	-1522(ra) # 80000bd6 <acquire>
    np->parent = p;
    800021d0:	055a3023          	sd	s5,64(s4)
    release(&wait_lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	ab4080e7          	jalr	-1356(ra) # 80000c8a <release>
    acquire(&np->lock);
    800021de:	8552                	mv	a0,s4
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	9f6080e7          	jalr	-1546(ra) # 80000bd6 <acquire>
    np->state = RUNNABLE;
    800021e8:	478d                	li	a5,3
    800021ea:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800021ee:	8552                	mv	a0,s4
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	a9a080e7          	jalr	-1382(ra) # 80000c8a <release>
}
    800021f8:	854a                	mv	a0,s2
    800021fa:	70e2                	ld	ra,56(sp)
    800021fc:	7442                	ld	s0,48(sp)
    800021fe:	74a2                	ld	s1,40(sp)
    80002200:	7902                	ld	s2,32(sp)
    80002202:	69e2                	ld	s3,24(sp)
    80002204:	6a42                	ld	s4,16(sp)
    80002206:	6aa2                	ld	s5,8(sp)
    80002208:	6121                	addi	sp,sp,64
    8000220a:	8082                	ret
        return -1;
    8000220c:	597d                	li	s2,-1
    8000220e:	b7ed                	j	800021f8 <fork+0x128>

0000000080002210 <scheduler>:
{
    80002210:	1101                	addi	sp,sp,-32
    80002212:	ec06                	sd	ra,24(sp)
    80002214:	e822                	sd	s0,16(sp)
    80002216:	e426                	sd	s1,8(sp)
    80002218:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    8000221a:	00006497          	auipc	s1,0x6
    8000221e:	71e48493          	addi	s1,s1,1822 # 80008938 <sched_pointer>
    80002222:	609c                	ld	a5,0(s1)
    80002224:	9782                	jalr	a5
    while (1)
    80002226:	bff5                	j	80002222 <scheduler+0x12>

0000000080002228 <sched>:
{
    80002228:	7179                	addi	sp,sp,-48
    8000222a:	f406                	sd	ra,40(sp)
    8000222c:	f022                	sd	s0,32(sp)
    8000222e:	ec26                	sd	s1,24(sp)
    80002230:	e84a                	sd	s2,16(sp)
    80002232:	e44e                	sd	s3,8(sp)
    80002234:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	94e080e7          	jalr	-1714(ra) # 80001b84 <myproc>
    8000223e:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	91c080e7          	jalr	-1764(ra) # 80000b5c <holding>
    80002248:	c53d                	beqz	a0,800022b6 <sched+0x8e>
    8000224a:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000224c:	2781                	sext.w	a5,a5
    8000224e:	079e                	slli	a5,a5,0x7
    80002250:	0000f717          	auipc	a4,0xf
    80002254:	a4070713          	addi	a4,a4,-1472 # 80010c90 <cpus>
    80002258:	97ba                	add	a5,a5,a4
    8000225a:	5fb8                	lw	a4,120(a5)
    8000225c:	4785                	li	a5,1
    8000225e:	06f71463          	bne	a4,a5,800022c6 <sched+0x9e>
    if (p->state == RUNNING)
    80002262:	4c98                	lw	a4,24(s1)
    80002264:	4791                	li	a5,4
    80002266:	06f70863          	beq	a4,a5,800022d6 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000226a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000226e:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002270:	ebbd                	bnez	a5,800022e6 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002272:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002274:	0000f917          	auipc	s2,0xf
    80002278:	a1c90913          	addi	s2,s2,-1508 # 80010c90 <cpus>
    8000227c:	2781                	sext.w	a5,a5
    8000227e:	079e                	slli	a5,a5,0x7
    80002280:	97ca                	add	a5,a5,s2
    80002282:	07c7a983          	lw	s3,124(a5)
    80002286:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002288:	2581                	sext.w	a1,a1
    8000228a:	059e                	slli	a1,a1,0x7
    8000228c:	05a1                	addi	a1,a1,8
    8000228e:	95ca                	add	a1,a1,s2
    80002290:	06848513          	addi	a0,s1,104
    80002294:	00000097          	auipc	ra,0x0
    80002298:	748080e7          	jalr	1864(ra) # 800029dc <swtch>
    8000229c:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000229e:	2781                	sext.w	a5,a5
    800022a0:	079e                	slli	a5,a5,0x7
    800022a2:	993e                	add	s2,s2,a5
    800022a4:	07392e23          	sw	s3,124(s2)
}
    800022a8:	70a2                	ld	ra,40(sp)
    800022aa:	7402                	ld	s0,32(sp)
    800022ac:	64e2                	ld	s1,24(sp)
    800022ae:	6942                	ld	s2,16(sp)
    800022b0:	69a2                	ld	s3,8(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret
        panic("sched p->lock");
    800022b6:	00006517          	auipc	a0,0x6
    800022ba:	f6250513          	addi	a0,a0,-158 # 80008218 <digits+0x1d8>
    800022be:	ffffe097          	auipc	ra,0xffffe
    800022c2:	282080e7          	jalr	642(ra) # 80000540 <panic>
        panic("sched locks");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	f6250513          	addi	a0,a0,-158 # 80008228 <digits+0x1e8>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	272080e7          	jalr	626(ra) # 80000540 <panic>
        panic("sched running");
    800022d6:	00006517          	auipc	a0,0x6
    800022da:	f6250513          	addi	a0,a0,-158 # 80008238 <digits+0x1f8>
    800022de:	ffffe097          	auipc	ra,0xffffe
    800022e2:	262080e7          	jalr	610(ra) # 80000540 <panic>
        panic("sched interruptible");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f6250513          	addi	a0,a0,-158 # 80008248 <digits+0x208>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	252080e7          	jalr	594(ra) # 80000540 <panic>

00000000800022f6 <yield>:
{
    800022f6:	1101                	addi	sp,sp,-32
    800022f8:	ec06                	sd	ra,24(sp)
    800022fa:	e822                	sd	s0,16(sp)
    800022fc:	e426                	sd	s1,8(sp)
    800022fe:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002300:	00000097          	auipc	ra,0x0
    80002304:	884080e7          	jalr	-1916(ra) # 80001b84 <myproc>
    80002308:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    80002312:	478d                	li	a5,3
    80002314:	cc9c                	sw	a5,24(s1)
    sched();
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	f12080e7          	jalr	-238(ra) # 80002228 <sched>
    release(&p->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	96a080e7          	jalr	-1686(ra) # 80000c8a <release>
}
    80002328:	60e2                	ld	ra,24(sp)
    8000232a:	6442                	ld	s0,16(sp)
    8000232c:	64a2                	ld	s1,8(sp)
    8000232e:	6105                	addi	sp,sp,32
    80002330:	8082                	ret

0000000080002332 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002332:	7179                	addi	sp,sp,-48
    80002334:	f406                	sd	ra,40(sp)
    80002336:	f022                	sd	s0,32(sp)
    80002338:	ec26                	sd	s1,24(sp)
    8000233a:	e84a                	sd	s2,16(sp)
    8000233c:	e44e                	sd	s3,8(sp)
    8000233e:	1800                	addi	s0,sp,48
    80002340:	89aa                	mv	s3,a0
    80002342:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002344:	00000097          	auipc	ra,0x0
    80002348:	840080e7          	jalr	-1984(ra) # 80001b84 <myproc>
    8000234c:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	888080e7          	jalr	-1912(ra) # 80000bd6 <acquire>
    release(lk);
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>

    // Go to sleep.
    p->chan = chan;
    80002360:	0334b423          	sd	s3,40(s1)
    p->state = SLEEPING;
    80002364:	4789                	li	a5,2
    80002366:	cc9c                	sw	a5,24(s1)

    sched();
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	ec0080e7          	jalr	-320(ra) # 80002228 <sched>

    // Tidy up.
    p->chan = 0;
    80002370:	0204b423          	sd	zero,40(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
    acquire(lk);
    8000237e:	854a                	mv	a0,s2
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	856080e7          	jalr	-1962(ra) # 80000bd6 <acquire>
}
    80002388:	70a2                	ld	ra,40(sp)
    8000238a:	7402                	ld	s0,32(sp)
    8000238c:	64e2                	ld	s1,24(sp)
    8000238e:	6942                	ld	s2,16(sp)
    80002390:	69a2                	ld	s3,8(sp)
    80002392:	6145                	addi	sp,sp,48
    80002394:	8082                	ret

0000000080002396 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002396:	7139                	addi	sp,sp,-64
    80002398:	fc06                	sd	ra,56(sp)
    8000239a:	f822                	sd	s0,48(sp)
    8000239c:	f426                	sd	s1,40(sp)
    8000239e:	f04a                	sd	s2,32(sp)
    800023a0:	ec4e                	sd	s3,24(sp)
    800023a2:	e852                	sd	s4,16(sp)
    800023a4:	e456                	sd	s5,8(sp)
    800023a6:	0080                	addi	s0,sp,64
    800023a8:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800023aa:	0000f497          	auipc	s1,0xf
    800023ae:	d1648493          	addi	s1,s1,-746 # 800110c0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800023b2:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023b4:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023b6:	00015917          	auipc	s2,0x15
    800023ba:	90a90913          	addi	s2,s2,-1782 # 80016cc0 <tickslock>
    800023be:	a811                	j	800023d2 <wakeup+0x3c>
            }
            release(&p->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8c8080e7          	jalr	-1848(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023ca:	17048493          	addi	s1,s1,368
    800023ce:	03248663          	beq	s1,s2,800023fa <wakeup+0x64>
        if (p != myproc())
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	7b2080e7          	jalr	1970(ra) # 80001b84 <myproc>
    800023da:	fea488e3          	beq	s1,a0,800023ca <wakeup+0x34>
            acquire(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	7f6080e7          	jalr	2038(ra) # 80000bd6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800023e8:	4c9c                	lw	a5,24(s1)
    800023ea:	fd379be3          	bne	a5,s3,800023c0 <wakeup+0x2a>
    800023ee:	749c                	ld	a5,40(s1)
    800023f0:	fd4798e3          	bne	a5,s4,800023c0 <wakeup+0x2a>
                p->state = RUNNABLE;
    800023f4:	0154ac23          	sw	s5,24(s1)
    800023f8:	b7e1                	j	800023c0 <wakeup+0x2a>
        }
    }
}
    800023fa:	70e2                	ld	ra,56(sp)
    800023fc:	7442                	ld	s0,48(sp)
    800023fe:	74a2                	ld	s1,40(sp)
    80002400:	7902                	ld	s2,32(sp)
    80002402:	69e2                	ld	s3,24(sp)
    80002404:	6a42                	ld	s4,16(sp)
    80002406:	6aa2                	ld	s5,8(sp)
    80002408:	6121                	addi	sp,sp,64
    8000240a:	8082                	ret

000000008000240c <reparent>:
{
    8000240c:	7179                	addi	sp,sp,-48
    8000240e:	f406                	sd	ra,40(sp)
    80002410:	f022                	sd	s0,32(sp)
    80002412:	ec26                	sd	s1,24(sp)
    80002414:	e84a                	sd	s2,16(sp)
    80002416:	e44e                	sd	s3,8(sp)
    80002418:	e052                	sd	s4,0(sp)
    8000241a:	1800                	addi	s0,sp,48
    8000241c:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241e:	0000f497          	auipc	s1,0xf
    80002422:	ca248493          	addi	s1,s1,-862 # 800110c0 <proc>
            pp->parent = initproc;
    80002426:	00006a17          	auipc	s4,0x6
    8000242a:	5f2a0a13          	addi	s4,s4,1522 # 80008a18 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000242e:	00015997          	auipc	s3,0x15
    80002432:	89298993          	addi	s3,s3,-1902 # 80016cc0 <tickslock>
    80002436:	a029                	j	80002440 <reparent+0x34>
    80002438:	17048493          	addi	s1,s1,368
    8000243c:	01348d63          	beq	s1,s3,80002456 <reparent+0x4a>
        if (pp->parent == p)
    80002440:	60bc                	ld	a5,64(s1)
    80002442:	ff279be3          	bne	a5,s2,80002438 <reparent+0x2c>
            pp->parent = initproc;
    80002446:	000a3503          	ld	a0,0(s4)
    8000244a:	e0a8                	sd	a0,64(s1)
            wakeup(initproc);
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	f4a080e7          	jalr	-182(ra) # 80002396 <wakeup>
    80002454:	b7d5                	j	80002438 <reparent+0x2c>
}
    80002456:	70a2                	ld	ra,40(sp)
    80002458:	7402                	ld	s0,32(sp)
    8000245a:	64e2                	ld	s1,24(sp)
    8000245c:	6942                	ld	s2,16(sp)
    8000245e:	69a2                	ld	s3,8(sp)
    80002460:	6a02                	ld	s4,0(sp)
    80002462:	6145                	addi	sp,sp,48
    80002464:	8082                	ret

0000000080002466 <exit>:
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	70c080e7          	jalr	1804(ra) # 80001b84 <myproc>
    80002480:	89aa                	mv	s3,a0
    if (p == initproc)
    80002482:	00006797          	auipc	a5,0x6
    80002486:	5967b783          	ld	a5,1430(a5) # 80008a18 <initproc>
    8000248a:	0d850493          	addi	s1,a0,216
    8000248e:	15850913          	addi	s2,a0,344
    80002492:	02a79363          	bne	a5,a0,800024b8 <exit+0x52>
        panic("init exiting");
    80002496:	00006517          	auipc	a0,0x6
    8000249a:	dca50513          	addi	a0,a0,-566 # 80008260 <digits+0x220>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	0a2080e7          	jalr	162(ra) # 80000540 <panic>
            fileclose(f);
    800024a6:	00002097          	auipc	ra,0x2
    800024aa:	4ee080e7          	jalr	1262(ra) # 80004994 <fileclose>
            p->ofile[fd] = 0;
    800024ae:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800024b2:	04a1                	addi	s1,s1,8
    800024b4:	01248563          	beq	s1,s2,800024be <exit+0x58>
        if (p->ofile[fd])
    800024b8:	6088                	ld	a0,0(s1)
    800024ba:	f575                	bnez	a0,800024a6 <exit+0x40>
    800024bc:	bfdd                	j	800024b2 <exit+0x4c>
    begin_op();
    800024be:	00002097          	auipc	ra,0x2
    800024c2:	00e080e7          	jalr	14(ra) # 800044cc <begin_op>
    iput(p->cwd);
    800024c6:	1589b503          	ld	a0,344(s3)
    800024ca:	00001097          	auipc	ra,0x1
    800024ce:	7f0080e7          	jalr	2032(ra) # 80003cba <iput>
    end_op();
    800024d2:	00002097          	auipc	ra,0x2
    800024d6:	078080e7          	jalr	120(ra) # 8000454a <end_op>
    p->cwd = 0;
    800024da:	1409bc23          	sd	zero,344(s3)
    acquire(&wait_lock);
    800024de:	0000f497          	auipc	s1,0xf
    800024e2:	bca48493          	addi	s1,s1,-1078 # 800110a8 <wait_lock>
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	6ee080e7          	jalr	1774(ra) # 80000bd6 <acquire>
    reparent(p);
    800024f0:	854e                	mv	a0,s3
    800024f2:	00000097          	auipc	ra,0x0
    800024f6:	f1a080e7          	jalr	-230(ra) # 8000240c <reparent>
    wakeup(p->parent);
    800024fa:	0409b503          	ld	a0,64(s3)
    800024fe:	00000097          	auipc	ra,0x0
    80002502:	e98080e7          	jalr	-360(ra) # 80002396 <wakeup>
    acquire(&p->lock);
    80002506:	854e                	mv	a0,s3
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	6ce080e7          	jalr	1742(ra) # 80000bd6 <acquire>
    p->xstate = status;
    80002510:	0349aa23          	sw	s4,52(s3)
    p->state = ZOMBIE;
    80002514:	4795                	li	a5,5
    80002516:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	76e080e7          	jalr	1902(ra) # 80000c8a <release>
    sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	d04080e7          	jalr	-764(ra) # 80002228 <sched>
    panic("zombie exit");
    8000252c:	00006517          	auipc	a0,0x6
    80002530:	d4450513          	addi	a0,a0,-700 # 80008270 <digits+0x230>
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	00c080e7          	jalr	12(ra) # 80000540 <panic>

000000008000253c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000253c:	7179                	addi	sp,sp,-48
    8000253e:	f406                	sd	ra,40(sp)
    80002540:	f022                	sd	s0,32(sp)
    80002542:	ec26                	sd	s1,24(sp)
    80002544:	e84a                	sd	s2,16(sp)
    80002546:	e44e                	sd	s3,8(sp)
    80002548:	1800                	addi	s0,sp,48
    8000254a:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000254c:	0000f497          	auipc	s1,0xf
    80002550:	b7448493          	addi	s1,s1,-1164 # 800110c0 <proc>
    80002554:	00014997          	auipc	s3,0x14
    80002558:	76c98993          	addi	s3,s3,1900 # 80016cc0 <tickslock>
    {
        acquire(&p->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	678080e7          	jalr	1656(ra) # 80000bd6 <acquire>
        if (p->pid == pid)
    80002566:	5c9c                	lw	a5,56(s1)
    80002568:	01278d63          	beq	a5,s2,80002582 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	71c080e7          	jalr	1820(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002576:	17048493          	addi	s1,s1,368
    8000257a:	ff3491e3          	bne	s1,s3,8000255c <kill+0x20>
    }
    return -1;
    8000257e:	557d                	li	a0,-1
    80002580:	a829                	j	8000259a <kill+0x5e>
            p->killed = 1;
    80002582:	4785                	li	a5,1
    80002584:	d89c                	sw	a5,48(s1)
            if (p->state == SLEEPING)
    80002586:	4c98                	lw	a4,24(s1)
    80002588:	4789                	li	a5,2
    8000258a:	00f70f63          	beq	a4,a5,800025a8 <kill+0x6c>
            release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	6fa080e7          	jalr	1786(ra) # 80000c8a <release>
            return 0;
    80002598:	4501                	li	a0,0
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6145                	addi	sp,sp,48
    800025a6:	8082                	ret
                p->state = RUNNABLE;
    800025a8:	478d                	li	a5,3
    800025aa:	cc9c                	sw	a5,24(s1)
    800025ac:	b7cd                	j	8000258e <kill+0x52>

00000000800025ae <setkilled>:

void setkilled(struct proc *p)
{
    800025ae:	1101                	addi	sp,sp,-32
    800025b0:	ec06                	sd	ra,24(sp)
    800025b2:	e822                	sd	s0,16(sp)
    800025b4:	e426                	sd	s1,8(sp)
    800025b6:	1000                	addi	s0,sp,32
    800025b8:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	61c080e7          	jalr	1564(ra) # 80000bd6 <acquire>
    p->killed = 1;
    800025c2:	4785                	li	a5,1
    800025c4:	d89c                	sw	a5,48(s1)
    release(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6c2080e7          	jalr	1730(ra) # 80000c8a <release>
}
    800025d0:	60e2                	ld	ra,24(sp)
    800025d2:	6442                	ld	s0,16(sp)
    800025d4:	64a2                	ld	s1,8(sp)
    800025d6:	6105                	addi	sp,sp,32
    800025d8:	8082                	ret

00000000800025da <killed>:

int killed(struct proc *p)
{
    800025da:	1101                	addi	sp,sp,-32
    800025dc:	ec06                	sd	ra,24(sp)
    800025de:	e822                	sd	s0,16(sp)
    800025e0:	e426                	sd	s1,8(sp)
    800025e2:	e04a                	sd	s2,0(sp)
    800025e4:	1000                	addi	s0,sp,32
    800025e6:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	5ee080e7          	jalr	1518(ra) # 80000bd6 <acquire>
    k = p->killed;
    800025f0:	0304a903          	lw	s2,48(s1)
    release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
    return k;
}
    800025fe:	854a                	mv	a0,s2
    80002600:	60e2                	ld	ra,24(sp)
    80002602:	6442                	ld	s0,16(sp)
    80002604:	64a2                	ld	s1,8(sp)
    80002606:	6902                	ld	s2,0(sp)
    80002608:	6105                	addi	sp,sp,32
    8000260a:	8082                	ret

000000008000260c <wait>:
{
    8000260c:	715d                	addi	sp,sp,-80
    8000260e:	e486                	sd	ra,72(sp)
    80002610:	e0a2                	sd	s0,64(sp)
    80002612:	fc26                	sd	s1,56(sp)
    80002614:	f84a                	sd	s2,48(sp)
    80002616:	f44e                	sd	s3,40(sp)
    80002618:	f052                	sd	s4,32(sp)
    8000261a:	ec56                	sd	s5,24(sp)
    8000261c:	e85a                	sd	s6,16(sp)
    8000261e:	e45e                	sd	s7,8(sp)
    80002620:	e062                	sd	s8,0(sp)
    80002622:	0880                	addi	s0,sp,80
    80002624:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	55e080e7          	jalr	1374(ra) # 80001b84 <myproc>
    8000262e:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002630:	0000f517          	auipc	a0,0xf
    80002634:	a7850513          	addi	a0,a0,-1416 # 800110a8 <wait_lock>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	59e080e7          	jalr	1438(ra) # 80000bd6 <acquire>
        havekids = 0;
    80002640:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002642:	4a15                	li	s4,5
                havekids = 1;
    80002644:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002646:	00014997          	auipc	s3,0x14
    8000264a:	67a98993          	addi	s3,s3,1658 # 80016cc0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000264e:	0000fc17          	auipc	s8,0xf
    80002652:	a5ac0c13          	addi	s8,s8,-1446 # 800110a8 <wait_lock>
        havekids = 0;
    80002656:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002658:	0000f497          	auipc	s1,0xf
    8000265c:	a6848493          	addi	s1,s1,-1432 # 800110c0 <proc>
    80002660:	a0bd                	j	800026ce <wait+0xc2>
                    pid = pp->pid;
    80002662:	0384a983          	lw	s3,56(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002666:	000b0e63          	beqz	s6,80002682 <wait+0x76>
    8000266a:	4691                	li	a3,4
    8000266c:	03448613          	addi	a2,s1,52
    80002670:	85da                	mv	a1,s6
    80002672:	05893503          	ld	a0,88(s2)
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	ff6080e7          	jalr	-10(ra) # 8000166c <copyout>
    8000267e:	02054563          	bltz	a0,800026a8 <wait+0x9c>
                    freeproc(pp);
    80002682:	8526                	mv	a0,s1
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	6b2080e7          	jalr	1714(ra) # 80001d36 <freeproc>
                    release(&pp->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5fc080e7          	jalr	1532(ra) # 80000c8a <release>
                    release(&wait_lock);
    80002696:	0000f517          	auipc	a0,0xf
    8000269a:	a1250513          	addi	a0,a0,-1518 # 800110a8 <wait_lock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	5ec080e7          	jalr	1516(ra) # 80000c8a <release>
                    return pid;
    800026a6:	a0b5                	j	80002712 <wait+0x106>
                        release(&pp->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	5e0080e7          	jalr	1504(ra) # 80000c8a <release>
                        release(&wait_lock);
    800026b2:	0000f517          	auipc	a0,0xf
    800026b6:	9f650513          	addi	a0,a0,-1546 # 800110a8 <wait_lock>
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>
                        return -1;
    800026c2:	59fd                	li	s3,-1
    800026c4:	a0b9                	j	80002712 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c6:	17048493          	addi	s1,s1,368
    800026ca:	03348463          	beq	s1,s3,800026f2 <wait+0xe6>
            if (pp->parent == p)
    800026ce:	60bc                	ld	a5,64(s1)
    800026d0:	ff279be3          	bne	a5,s2,800026c6 <wait+0xba>
                acquire(&pp->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	500080e7          	jalr	1280(ra) # 80000bd6 <acquire>
                if (pp->state == ZOMBIE)
    800026de:	4c9c                	lw	a5,24(s1)
    800026e0:	f94781e3          	beq	a5,s4,80002662 <wait+0x56>
                release(&pp->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5a4080e7          	jalr	1444(ra) # 80000c8a <release>
                havekids = 1;
    800026ee:	8756                	mv	a4,s5
    800026f0:	bfd9                	j	800026c6 <wait+0xba>
        if (!havekids || killed(p))
    800026f2:	c719                	beqz	a4,80002700 <wait+0xf4>
    800026f4:	854a                	mv	a0,s2
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	ee4080e7          	jalr	-284(ra) # 800025da <killed>
    800026fe:	c51d                	beqz	a0,8000272c <wait+0x120>
            release(&wait_lock);
    80002700:	0000f517          	auipc	a0,0xf
    80002704:	9a850513          	addi	a0,a0,-1624 # 800110a8 <wait_lock>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	582080e7          	jalr	1410(ra) # 80000c8a <release>
            return -1;
    80002710:	59fd                	li	s3,-1
}
    80002712:	854e                	mv	a0,s3
    80002714:	60a6                	ld	ra,72(sp)
    80002716:	6406                	ld	s0,64(sp)
    80002718:	74e2                	ld	s1,56(sp)
    8000271a:	7942                	ld	s2,48(sp)
    8000271c:	79a2                	ld	s3,40(sp)
    8000271e:	7a02                	ld	s4,32(sp)
    80002720:	6ae2                	ld	s5,24(sp)
    80002722:	6b42                	ld	s6,16(sp)
    80002724:	6ba2                	ld	s7,8(sp)
    80002726:	6c02                	ld	s8,0(sp)
    80002728:	6161                	addi	sp,sp,80
    8000272a:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000272c:	85e2                	mv	a1,s8
    8000272e:	854a                	mv	a0,s2
    80002730:	00000097          	auipc	ra,0x0
    80002734:	c02080e7          	jalr	-1022(ra) # 80002332 <sleep>
        havekids = 0;
    80002738:	bf39                	j	80002656 <wait+0x4a>

000000008000273a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	e052                	sd	s4,0(sp)
    80002748:	1800                	addi	s0,sp,48
    8000274a:	84aa                	mv	s1,a0
    8000274c:	892e                	mv	s2,a1
    8000274e:	89b2                	mv	s3,a2
    80002750:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	432080e7          	jalr	1074(ra) # 80001b84 <myproc>
    if (user_dst)
    8000275a:	c08d                	beqz	s1,8000277c <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000275c:	86d2                	mv	a3,s4
    8000275e:	864e                	mv	a2,s3
    80002760:	85ca                	mv	a1,s2
    80002762:	6d28                	ld	a0,88(a0)
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	f08080e7          	jalr	-248(ra) # 8000166c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000276c:	70a2                	ld	ra,40(sp)
    8000276e:	7402                	ld	s0,32(sp)
    80002770:	64e2                	ld	s1,24(sp)
    80002772:	6942                	ld	s2,16(sp)
    80002774:	69a2                	ld	s3,8(sp)
    80002776:	6a02                	ld	s4,0(sp)
    80002778:	6145                	addi	sp,sp,48
    8000277a:	8082                	ret
        memmove((char *)dst, src, len);
    8000277c:	000a061b          	sext.w	a2,s4
    80002780:	85ce                	mv	a1,s3
    80002782:	854a                	mv	a0,s2
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	5aa080e7          	jalr	1450(ra) # 80000d2e <memmove>
        return 0;
    8000278c:	8526                	mv	a0,s1
    8000278e:	bff9                	j	8000276c <either_copyout+0x32>

0000000080002790 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002790:	7179                	addi	sp,sp,-48
    80002792:	f406                	sd	ra,40(sp)
    80002794:	f022                	sd	s0,32(sp)
    80002796:	ec26                	sd	s1,24(sp)
    80002798:	e84a                	sd	s2,16(sp)
    8000279a:	e44e                	sd	s3,8(sp)
    8000279c:	e052                	sd	s4,0(sp)
    8000279e:	1800                	addi	s0,sp,48
    800027a0:	892a                	mv	s2,a0
    800027a2:	84ae                	mv	s1,a1
    800027a4:	89b2                	mv	s3,a2
    800027a6:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	3dc080e7          	jalr	988(ra) # 80001b84 <myproc>
    if (user_src)
    800027b0:	c08d                	beqz	s1,800027d2 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027b2:	86d2                	mv	a3,s4
    800027b4:	864e                	mv	a2,s3
    800027b6:	85ca                	mv	a1,s2
    800027b8:	6d28                	ld	a0,88(a0)
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	f3e080e7          	jalr	-194(ra) # 800016f8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027c2:	70a2                	ld	ra,40(sp)
    800027c4:	7402                	ld	s0,32(sp)
    800027c6:	64e2                	ld	s1,24(sp)
    800027c8:	6942                	ld	s2,16(sp)
    800027ca:	69a2                	ld	s3,8(sp)
    800027cc:	6a02                	ld	s4,0(sp)
    800027ce:	6145                	addi	sp,sp,48
    800027d0:	8082                	ret
        memmove(dst, (char *)src, len);
    800027d2:	000a061b          	sext.w	a2,s4
    800027d6:	85ce                	mv	a1,s3
    800027d8:	854a                	mv	a0,s2
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	554080e7          	jalr	1364(ra) # 80000d2e <memmove>
        return 0;
    800027e2:	8526                	mv	a0,s1
    800027e4:	bff9                	j	800027c2 <either_copyin+0x32>

00000000800027e6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027e6:	715d                	addi	sp,sp,-80
    800027e8:	e486                	sd	ra,72(sp)
    800027ea:	e0a2                	sd	s0,64(sp)
    800027ec:	fc26                	sd	s1,56(sp)
    800027ee:	f84a                	sd	s2,48(sp)
    800027f0:	f44e                	sd	s3,40(sp)
    800027f2:	f052                	sd	s4,32(sp)
    800027f4:	ec56                	sd	s5,24(sp)
    800027f6:	e85a                	sd	s6,16(sp)
    800027f8:	e45e                	sd	s7,8(sp)
    800027fa:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800027fc:	00006517          	auipc	a0,0x6
    80002800:	8cc50513          	addi	a0,a0,-1844 # 800080c8 <digits+0x88>
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	d86080e7          	jalr	-634(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000280c:	0000f497          	auipc	s1,0xf
    80002810:	a1448493          	addi	s1,s1,-1516 # 80011220 <proc+0x160>
    80002814:	00014917          	auipc	s2,0x14
    80002818:	60c90913          	addi	s2,s2,1548 # 80016e20 <bcache+0x148>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281c:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000281e:	00006997          	auipc	s3,0x6
    80002822:	a6298993          	addi	s3,s3,-1438 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    80002826:	00006a97          	auipc	s5,0x6
    8000282a:	a62a8a93          	addi	s5,s5,-1438 # 80008288 <digits+0x248>
        printf("\n");
    8000282e:	00006a17          	auipc	s4,0x6
    80002832:	89aa0a13          	addi	s4,s4,-1894 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002836:	00006b97          	auipc	s7,0x6
    8000283a:	b62b8b93          	addi	s7,s7,-1182 # 80008398 <states.0>
    8000283e:	a00d                	j	80002860 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002840:	ed86a583          	lw	a1,-296(a3)
    80002844:	8556                	mv	a0,s5
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	d44080e7          	jalr	-700(ra) # 8000058a <printf>
        printf("\n");
    8000284e:	8552                	mv	a0,s4
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	d3a080e7          	jalr	-710(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002858:	17048493          	addi	s1,s1,368
    8000285c:	03248263          	beq	s1,s2,80002880 <procdump+0x9a>
        if (p->state == UNUSED)
    80002860:	86a6                	mv	a3,s1
    80002862:	eb84a783          	lw	a5,-328(s1)
    80002866:	dbed                	beqz	a5,80002858 <procdump+0x72>
            state = "???";
    80002868:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286a:	fcfb6be3          	bltu	s6,a5,80002840 <procdump+0x5a>
    8000286e:	02079713          	slli	a4,a5,0x20
    80002872:	01d75793          	srli	a5,a4,0x1d
    80002876:	97de                	add	a5,a5,s7
    80002878:	6390                	ld	a2,0(a5)
    8000287a:	f279                	bnez	a2,80002840 <procdump+0x5a>
            state = "???";
    8000287c:	864e                	mv	a2,s3
    8000287e:	b7c9                	j	80002840 <procdump+0x5a>
    }
}
    80002880:	60a6                	ld	ra,72(sp)
    80002882:	6406                	ld	s0,64(sp)
    80002884:	74e2                	ld	s1,56(sp)
    80002886:	7942                	ld	s2,48(sp)
    80002888:	79a2                	ld	s3,40(sp)
    8000288a:	7a02                	ld	s4,32(sp)
    8000288c:	6ae2                	ld	s5,24(sp)
    8000288e:	6b42                	ld	s6,16(sp)
    80002890:	6ba2                	ld	s7,8(sp)
    80002892:	6161                	addi	sp,sp,80
    80002894:	8082                	ret

0000000080002896 <schedls>:

void schedls()
{
    80002896:	1101                	addi	sp,sp,-32
    80002898:	ec06                	sd	ra,24(sp)
    8000289a:	e822                	sd	s0,16(sp)
    8000289c:	e426                	sd	s1,8(sp)
    8000289e:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	9f850513          	addi	a0,a0,-1544 # 80008298 <digits+0x258>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	ce2080e7          	jalr	-798(ra) # 8000058a <printf>
    printf("====================================\n");
    800028b0:	00006517          	auipc	a0,0x6
    800028b4:	a1050513          	addi	a0,a0,-1520 # 800082c0 <digits+0x280>
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	cd2080e7          	jalr	-814(ra) # 8000058a <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800028c0:	00006717          	auipc	a4,0x6
    800028c4:	0d873703          	ld	a4,216(a4) # 80008998 <available_schedulers+0x10>
    800028c8:	00006797          	auipc	a5,0x6
    800028cc:	0707b783          	ld	a5,112(a5) # 80008938 <sched_pointer>
    800028d0:	08f70763          	beq	a4,a5,8000295e <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800028d4:	00006517          	auipc	a0,0x6
    800028d8:	a1450513          	addi	a0,a0,-1516 # 800082e8 <digits+0x2a8>
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cae080e7          	jalr	-850(ra) # 8000058a <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800028e4:	00006497          	auipc	s1,0x6
    800028e8:	06c48493          	addi	s1,s1,108 # 80008950 <initcode>
    800028ec:	48b0                	lw	a2,80(s1)
    800028ee:	00006597          	auipc	a1,0x6
    800028f2:	09a58593          	addi	a1,a1,154 # 80008988 <available_schedulers>
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	a0250513          	addi	a0,a0,-1534 # 800082f8 <digits+0x2b8>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c8c080e7          	jalr	-884(ra) # 8000058a <printf>
        if (available_schedulers[i].impl == sched_pointer)
    80002906:	74b8                	ld	a4,104(s1)
    80002908:	00006797          	auipc	a5,0x6
    8000290c:	0307b783          	ld	a5,48(a5) # 80008938 <sched_pointer>
    80002910:	06f70063          	beq	a4,a5,80002970 <schedls+0xda>
            printf("   \t");
    80002914:	00006517          	auipc	a0,0x6
    80002918:	9d450513          	addi	a0,a0,-1580 # 800082e8 <digits+0x2a8>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c6e080e7          	jalr	-914(ra) # 8000058a <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002924:	00006617          	auipc	a2,0x6
    80002928:	09c62603          	lw	a2,156(a2) # 800089c0 <available_schedulers+0x38>
    8000292c:	00006597          	auipc	a1,0x6
    80002930:	07c58593          	addi	a1,a1,124 # 800089a8 <available_schedulers+0x20>
    80002934:	00006517          	auipc	a0,0x6
    80002938:	9c450513          	addi	a0,a0,-1596 # 800082f8 <digits+0x2b8>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c4e080e7          	jalr	-946(ra) # 8000058a <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002944:	00006517          	auipc	a0,0x6
    80002948:	9bc50513          	addi	a0,a0,-1604 # 80008300 <digits+0x2c0>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c3e080e7          	jalr	-962(ra) # 8000058a <printf>
}
    80002954:	60e2                	ld	ra,24(sp)
    80002956:	6442                	ld	s0,16(sp)
    80002958:	64a2                	ld	s1,8(sp)
    8000295a:	6105                	addi	sp,sp,32
    8000295c:	8082                	ret
            printf("[*]\t");
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	99250513          	addi	a0,a0,-1646 # 800082f0 <digits+0x2b0>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c24080e7          	jalr	-988(ra) # 8000058a <printf>
    8000296e:	bf9d                	j	800028e4 <schedls+0x4e>
    80002970:	00006517          	auipc	a0,0x6
    80002974:	98050513          	addi	a0,a0,-1664 # 800082f0 <digits+0x2b0>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	c12080e7          	jalr	-1006(ra) # 8000058a <printf>
    80002980:	b755                	j	80002924 <schedls+0x8e>

0000000080002982 <schedset>:

void schedset(int id)
{
    80002982:	1141                	addi	sp,sp,-16
    80002984:	e406                	sd	ra,8(sp)
    80002986:	e022                	sd	s0,0(sp)
    80002988:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    8000298a:	4705                	li	a4,1
    8000298c:	02a76f63          	bltu	a4,a0,800029ca <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002990:	00551793          	slli	a5,a0,0x5
    80002994:	00006717          	auipc	a4,0x6
    80002998:	fbc70713          	addi	a4,a4,-68 # 80008950 <initcode>
    8000299c:	973e                	add	a4,a4,a5
    8000299e:	6738                	ld	a4,72(a4)
    800029a0:	00006697          	auipc	a3,0x6
    800029a4:	f8e6bc23          	sd	a4,-104(a3) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029a8:	00006597          	auipc	a1,0x6
    800029ac:	fe058593          	addi	a1,a1,-32 # 80008988 <available_schedulers>
    800029b0:	95be                	add	a1,a1,a5
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	98e50513          	addi	a0,a0,-1650 # 80008340 <digits+0x300>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bd0080e7          	jalr	-1072(ra) # 8000058a <printf>
    800029c2:	60a2                	ld	ra,8(sp)
    800029c4:	6402                	ld	s0,0(sp)
    800029c6:	0141                	addi	sp,sp,16
    800029c8:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	94e50513          	addi	a0,a0,-1714 # 80008318 <digits+0x2d8>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb8080e7          	jalr	-1096(ra) # 8000058a <printf>
        return;
    800029da:	b7e5                	j	800029c2 <schedset+0x40>

00000000800029dc <swtch>:
    800029dc:	00153023          	sd	ra,0(a0)
    800029e0:	00253423          	sd	sp,8(a0)
    800029e4:	e900                	sd	s0,16(a0)
    800029e6:	ed04                	sd	s1,24(a0)
    800029e8:	03253023          	sd	s2,32(a0)
    800029ec:	03353423          	sd	s3,40(a0)
    800029f0:	03453823          	sd	s4,48(a0)
    800029f4:	03553c23          	sd	s5,56(a0)
    800029f8:	05653023          	sd	s6,64(a0)
    800029fc:	05753423          	sd	s7,72(a0)
    80002a00:	05853823          	sd	s8,80(a0)
    80002a04:	05953c23          	sd	s9,88(a0)
    80002a08:	07a53023          	sd	s10,96(a0)
    80002a0c:	07b53423          	sd	s11,104(a0)
    80002a10:	0005b083          	ld	ra,0(a1)
    80002a14:	0085b103          	ld	sp,8(a1)
    80002a18:	6980                	ld	s0,16(a1)
    80002a1a:	6d84                	ld	s1,24(a1)
    80002a1c:	0205b903          	ld	s2,32(a1)
    80002a20:	0285b983          	ld	s3,40(a1)
    80002a24:	0305ba03          	ld	s4,48(a1)
    80002a28:	0385ba83          	ld	s5,56(a1)
    80002a2c:	0405bb03          	ld	s6,64(a1)
    80002a30:	0485bb83          	ld	s7,72(a1)
    80002a34:	0505bc03          	ld	s8,80(a1)
    80002a38:	0585bc83          	ld	s9,88(a1)
    80002a3c:	0605bd03          	ld	s10,96(a1)
    80002a40:	0685bd83          	ld	s11,104(a1)
    80002a44:	8082                	ret

0000000080002a46 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a46:	1141                	addi	sp,sp,-16
    80002a48:	e406                	sd	ra,8(sp)
    80002a4a:	e022                	sd	s0,0(sp)
    80002a4c:	0800                	addi	s0,sp,16
    initlock(&tickslock, "time");
    80002a4e:	00006597          	auipc	a1,0x6
    80002a52:	97a58593          	addi	a1,a1,-1670 # 800083c8 <states.0+0x30>
    80002a56:	00014517          	auipc	a0,0x14
    80002a5a:	26a50513          	addi	a0,a0,618 # 80016cc0 <tickslock>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	0e8080e7          	jalr	232(ra) # 80000b46 <initlock>
}
    80002a66:	60a2                	ld	ra,8(sp)
    80002a68:	6402                	ld	s0,0(sp)
    80002a6a:	0141                	addi	sp,sp,16
    80002a6c:	8082                	ret

0000000080002a6e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a6e:	1141                	addi	sp,sp,-16
    80002a70:	e422                	sd	s0,8(sp)
    80002a72:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a74:	00003797          	auipc	a5,0x3
    80002a78:	56c78793          	addi	a5,a5,1388 # 80005fe0 <kernelvec>
    80002a7c:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    80002a80:	6422                	ld	s0,8(sp)
    80002a82:	0141                	addi	sp,sp,16
    80002a84:	8082                	ret

0000000080002a86 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a86:	1141                	addi	sp,sp,-16
    80002a88:	e406                	sd	ra,8(sp)
    80002a8a:	e022                	sd	s0,0(sp)
    80002a8c:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	0f6080e7          	jalr	246(ra) # 80001b84 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9c:	10079073          	csrw	sstatus,a5
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002aa0:	00004697          	auipc	a3,0x4
    80002aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80002aa8:	00004717          	auipc	a4,0x4
    80002aac:	55870713          	addi	a4,a4,1368 # 80007000 <_trampoline>
    80002ab0:	8f15                	sub	a4,a4,a3
    80002ab2:	040007b7          	lui	a5,0x4000
    80002ab6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ab8:	07b2                	slli	a5,a5,0xc
    80002aba:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abc:	10571073          	csrw	stvec,a4
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ac0:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ac2:	18002673          	csrr	a2,satp
    80002ac6:	e310                	sd	a2,0(a4)
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ac8:	7130                	ld	a2,96(a0)
    80002aca:	6538                	ld	a4,72(a0)
    80002acc:	6585                	lui	a1,0x1
    80002ace:	972e                	add	a4,a4,a1
    80002ad0:	e618                	sd	a4,8(a2)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80002ad2:	7138                	ld	a4,96(a0)
    80002ad4:	00000617          	auipc	a2,0x0
    80002ad8:	13060613          	addi	a2,a2,304 # 80002c04 <usertrap>
    80002adc:	eb10                	sd	a2,16(a4)
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ade:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ae0:	8612                	mv	a2,tp
    80002ae2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae4:	10002773          	csrr	a4,sstatus
    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ae8:	eff77713          	andi	a4,a4,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002aec:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af0:	10071073          	csrw	sstatus,a4
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);
    80002af4:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002af6:	6f18                	ld	a4,24(a4)
    80002af8:	14171073          	csrw	sepc,a4

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);
    80002afc:	6d28                	ld	a0,88(a0)
    80002afe:	8131                	srli	a0,a0,0xc

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b00:	00004717          	auipc	a4,0x4
    80002b04:	59c70713          	addi	a4,a4,1436 # 8000709c <userret>
    80002b08:	8f15                	sub	a4,a4,a3
    80002b0a:	97ba                	add	a5,a5,a4
    ((void (*)(uint64))trampoline_userret)(satp);
    80002b0c:	577d                	li	a4,-1
    80002b0e:	177e                	slli	a4,a4,0x3f
    80002b10:	8d59                	or	a0,a0,a4
    80002b12:	9782                	jalr	a5
}
    80002b14:	60a2                	ld	ra,8(sp)
    80002b16:	6402                	ld	s0,0(sp)
    80002b18:	0141                	addi	sp,sp,16
    80002b1a:	8082                	ret

0000000080002b1c <clockintr>:
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    80002b26:	00014497          	auipc	s1,0x14
    80002b2a:	19a48493          	addi	s1,s1,410 # 80016cc0 <tickslock>
    80002b2e:	8526                	mv	a0,s1
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	0a6080e7          	jalr	166(ra) # 80000bd6 <acquire>
    ticks++;
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	ee850513          	addi	a0,a0,-280 # 80008a20 <ticks>
    80002b40:	411c                	lw	a5,0(a0)
    80002b42:	2785                	addiw	a5,a5,1
    80002b44:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	850080e7          	jalr	-1968(ra) # 80002396 <wakeup>
    release(&tickslock);
    80002b4e:	8526                	mv	a0,s1
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	13a080e7          	jalr	314(ra) # 80000c8a <release>
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6c:	14202773          	csrr	a4,scause
    uint64 scause = r_scause();

    if ((scause & 0x8000000000000000L) &&
    80002b70:	00074d63          	bltz	a4,80002b8a <devintr+0x28>
        if (irq)
            plic_complete(irq);

        return 1;
    }
    else if (scause == 0x8000000000000001L)
    80002b74:	57fd                	li	a5,-1
    80002b76:	17fe                	slli	a5,a5,0x3f
    80002b78:	0785                	addi	a5,a5,1

        return 2;
    }
    else
    {
        return 0;
    80002b7a:	4501                	li	a0,0
    else if (scause == 0x8000000000000001L)
    80002b7c:	06f70363          	beq	a4,a5,80002be2 <devintr+0x80>
    }
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	64a2                	ld	s1,8(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret
        (scause & 0xff) == 9)
    80002b8a:	0ff77793          	zext.b	a5,a4
    if ((scause & 0x8000000000000000L) &&
    80002b8e:	46a5                	li	a3,9
    80002b90:	fed792e3          	bne	a5,a3,80002b74 <devintr+0x12>
        int irq = plic_claim();
    80002b94:	00003097          	auipc	ra,0x3
    80002b98:	554080e7          	jalr	1364(ra) # 800060e8 <plic_claim>
    80002b9c:	84aa                	mv	s1,a0
        if (irq == UART0_IRQ)
    80002b9e:	47a9                	li	a5,10
    80002ba0:	02f50763          	beq	a0,a5,80002bce <devintr+0x6c>
        else if (irq == VIRTIO0_IRQ)
    80002ba4:	4785                	li	a5,1
    80002ba6:	02f50963          	beq	a0,a5,80002bd8 <devintr+0x76>
        return 1;
    80002baa:	4505                	li	a0,1
        else if (irq)
    80002bac:	d8f1                	beqz	s1,80002b80 <devintr+0x1e>
            printf("unexpected interrupt irq=%d\n", irq);
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	82050513          	addi	a0,a0,-2016 # 800083d0 <states.0+0x38>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9d2080e7          	jalr	-1582(ra) # 8000058a <printf>
            plic_complete(irq);
    80002bc0:	8526                	mv	a0,s1
    80002bc2:	00003097          	auipc	ra,0x3
    80002bc6:	54a080e7          	jalr	1354(ra) # 8000610c <plic_complete>
        return 1;
    80002bca:	4505                	li	a0,1
    80002bcc:	bf55                	j	80002b80 <devintr+0x1e>
            uartintr();
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	dca080e7          	jalr	-566(ra) # 80000998 <uartintr>
    80002bd6:	b7ed                	j	80002bc0 <devintr+0x5e>
            virtio_disk_intr();
    80002bd8:	00004097          	auipc	ra,0x4
    80002bdc:	9fc080e7          	jalr	-1540(ra) # 800065d4 <virtio_disk_intr>
    80002be0:	b7c5                	j	80002bc0 <devintr+0x5e>
        if (cpuid() == 0)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	f76080e7          	jalr	-138(ra) # 80001b58 <cpuid>
    80002bea:	c901                	beqz	a0,80002bfa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bec:	144027f3          	csrr	a5,sip
        w_sip(r_sip() & ~2);
    80002bf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bf2:	14479073          	csrw	sip,a5
        return 2;
    80002bf6:	4509                	li	a0,2
    80002bf8:	b761                	j	80002b80 <devintr+0x1e>
            clockintr();
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	f22080e7          	jalr	-222(ra) # 80002b1c <clockintr>
    80002c02:	b7ed                	j	80002bec <devintr+0x8a>

0000000080002c04 <usertrap>:
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c10:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c14:	1007f793          	andi	a5,a5,256
    80002c18:	e3b1                	bnez	a5,80002c5c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c1a:	00003797          	auipc	a5,0x3
    80002c1e:	3c678793          	addi	a5,a5,966 # 80005fe0 <kernelvec>
    80002c22:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	f5e080e7          	jalr	-162(ra) # 80001b84 <myproc>
    80002c2e:	84aa                	mv	s1,a0
    p->trapframe->epc = r_sepc();
    80002c30:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c32:	14102773          	csrr	a4,sepc
    80002c36:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c38:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    80002c3c:	47a1                	li	a5,8
    80002c3e:	02f70763          	beq	a4,a5,80002c6c <usertrap+0x68>
    else if ((which_dev = devintr()) != 0)
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	f20080e7          	jalr	-224(ra) # 80002b62 <devintr>
    80002c4a:	892a                	mv	s2,a0
    80002c4c:	c151                	beqz	a0,80002cd0 <usertrap+0xcc>
    if (killed(p))
    80002c4e:	8526                	mv	a0,s1
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	98a080e7          	jalr	-1654(ra) # 800025da <killed>
    80002c58:	c929                	beqz	a0,80002caa <usertrap+0xa6>
    80002c5a:	a099                	j	80002ca0 <usertrap+0x9c>
        panic("usertrap: not from user mode");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	79450513          	addi	a0,a0,1940 # 800083f0 <states.0+0x58>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8dc080e7          	jalr	-1828(ra) # 80000540 <panic>
        if (killed(p))
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	96e080e7          	jalr	-1682(ra) # 800025da <killed>
    80002c74:	e921                	bnez	a0,80002cc4 <usertrap+0xc0>
        p->trapframe->epc += 4;
    80002c76:	70b8                	ld	a4,96(s1)
    80002c78:	6f1c                	ld	a5,24(a4)
    80002c7a:	0791                	addi	a5,a5,4
    80002c7c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c86:	10079073          	csrw	sstatus,a5
        syscall();
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	2d8080e7          	jalr	728(ra) # 80002f62 <syscall>
    if (killed(p))
    80002c92:	8526                	mv	a0,s1
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	946080e7          	jalr	-1722(ra) # 800025da <killed>
    80002c9c:	c911                	beqz	a0,80002cb0 <usertrap+0xac>
    80002c9e:	4901                	li	s2,0
        exit(-1);
    80002ca0:	557d                	li	a0,-1
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	7c4080e7          	jalr	1988(ra) # 80002466 <exit>
    if (which_dev == 2)
    80002caa:	4789                	li	a5,2
    80002cac:	04f90f63          	beq	s2,a5,80002d0a <usertrap+0x106>
    usertrapret();
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	dd6080e7          	jalr	-554(ra) # 80002a86 <usertrapret>
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6902                	ld	s2,0(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
            exit(-1);
    80002cc4:	557d                	li	a0,-1
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	7a0080e7          	jalr	1952(ra) # 80002466 <exit>
    80002cce:	b765                	j	80002c76 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd0:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cd4:	5c90                	lw	a2,56(s1)
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	73a50513          	addi	a0,a0,1850 # 80008410 <states.0+0x78>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8ac080e7          	jalr	-1876(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cea:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	75250513          	addi	a0,a0,1874 # 80008440 <states.0+0xa8>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	894080e7          	jalr	-1900(ra) # 8000058a <printf>
        setkilled(p);
    80002cfe:	8526                	mv	a0,s1
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	8ae080e7          	jalr	-1874(ra) # 800025ae <setkilled>
    80002d08:	b769                	j	80002c92 <usertrap+0x8e>
        yield(YIELD_TIMER);
    80002d0a:	4505                	li	a0,1
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	5ea080e7          	jalr	1514(ra) # 800022f6 <yield>
    80002d14:	bf71                	j	80002cb0 <usertrap+0xac>

0000000080002d16 <kerneltrap>:
{
    80002d16:	7179                	addi	sp,sp,-48
    80002d18:	f406                	sd	ra,40(sp)
    80002d1a:	f022                	sd	s0,32(sp)
    80002d1c:	ec26                	sd	s1,24(sp)
    80002d1e:	e84a                	sd	s2,16(sp)
    80002d20:	e44e                	sd	s3,8(sp)
    80002d22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d2c:	142029f3          	csrr	s3,scause
    if ((sstatus & SSTATUS_SPP) == 0)
    80002d30:	1004f793          	andi	a5,s1,256
    80002d34:	cb85                	beqz	a5,80002d64 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d3a:	8b89                	andi	a5,a5,2
    if (intr_get() != 0)
    80002d3c:	ef85                	bnez	a5,80002d74 <kerneltrap+0x5e>
    if ((which_dev = devintr()) == 0)
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	e24080e7          	jalr	-476(ra) # 80002b62 <devintr>
    80002d46:	cd1d                	beqz	a0,80002d84 <kerneltrap+0x6e>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d48:	4789                	li	a5,2
    80002d4a:	06f50a63          	beq	a0,a5,80002dbe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d4e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d52:	10049073          	csrw	sstatus,s1
}
    80002d56:	70a2                	ld	ra,40(sp)
    80002d58:	7402                	ld	s0,32(sp)
    80002d5a:	64e2                	ld	s1,24(sp)
    80002d5c:	6942                	ld	s2,16(sp)
    80002d5e:	69a2                	ld	s3,8(sp)
    80002d60:	6145                	addi	sp,sp,48
    80002d62:	8082                	ret
        panic("kerneltrap: not from supervisor mode");
    80002d64:	00005517          	auipc	a0,0x5
    80002d68:	6fc50513          	addi	a0,a0,1788 # 80008460 <states.0+0xc8>
    80002d6c:	ffffd097          	auipc	ra,0xffffd
    80002d70:	7d4080e7          	jalr	2004(ra) # 80000540 <panic>
        panic("kerneltrap: interrupts enabled");
    80002d74:	00005517          	auipc	a0,0x5
    80002d78:	71450513          	addi	a0,a0,1812 # 80008488 <states.0+0xf0>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7c4080e7          	jalr	1988(ra) # 80000540 <panic>
        printf("scause %p\n", scause);
    80002d84:	85ce                	mv	a1,s3
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	72250513          	addi	a0,a0,1826 # 800084a8 <states.0+0x110>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	7fc080e7          	jalr	2044(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d9a:	14302673          	csrr	a2,stval
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d9e:	00005517          	auipc	a0,0x5
    80002da2:	71a50513          	addi	a0,a0,1818 # 800084b8 <states.0+0x120>
    80002da6:	ffffd097          	auipc	ra,0xffffd
    80002daa:	7e4080e7          	jalr	2020(ra) # 8000058a <printf>
        panic("kerneltrap");
    80002dae:	00005517          	auipc	a0,0x5
    80002db2:	72250513          	addi	a0,a0,1826 # 800084d0 <states.0+0x138>
    80002db6:	ffffd097          	auipc	ra,0xffffd
    80002dba:	78a080e7          	jalr	1930(ra) # 80000540 <panic>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	dc6080e7          	jalr	-570(ra) # 80001b84 <myproc>
    80002dc6:	d541                	beqz	a0,80002d4e <kerneltrap+0x38>
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	dbc080e7          	jalr	-580(ra) # 80001b84 <myproc>
    80002dd0:	4d18                	lw	a4,24(a0)
    80002dd2:	4791                	li	a5,4
    80002dd4:	f6f71de3          	bne	a4,a5,80002d4e <kerneltrap+0x38>
        yield(YIELD_OTHER);
    80002dd8:	4509                	li	a0,2
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	51c080e7          	jalr	1308(ra) # 800022f6 <yield>
    80002de2:	b7b5                	j	80002d4e <kerneltrap+0x38>

0000000080002de4 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	1000                	addi	s0,sp,32
    80002dee:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	d94080e7          	jalr	-620(ra) # 80001b84 <myproc>
    switch (n)
    80002df8:	4795                	li	a5,5
    80002dfa:	0497e163          	bltu	a5,s1,80002e3c <argraw+0x58>
    80002dfe:	048a                	slli	s1,s1,0x2
    80002e00:	00005717          	auipc	a4,0x5
    80002e04:	70870713          	addi	a4,a4,1800 # 80008508 <states.0+0x170>
    80002e08:	94ba                	add	s1,s1,a4
    80002e0a:	409c                	lw	a5,0(s1)
    80002e0c:	97ba                	add	a5,a5,a4
    80002e0e:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002e10:	713c                	ld	a5,96(a0)
    80002e12:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	64a2                	ld	s1,8(sp)
    80002e1a:	6105                	addi	sp,sp,32
    80002e1c:	8082                	ret
        return p->trapframe->a1;
    80002e1e:	713c                	ld	a5,96(a0)
    80002e20:	7fa8                	ld	a0,120(a5)
    80002e22:	bfcd                	j	80002e14 <argraw+0x30>
        return p->trapframe->a2;
    80002e24:	713c                	ld	a5,96(a0)
    80002e26:	63c8                	ld	a0,128(a5)
    80002e28:	b7f5                	j	80002e14 <argraw+0x30>
        return p->trapframe->a3;
    80002e2a:	713c                	ld	a5,96(a0)
    80002e2c:	67c8                	ld	a0,136(a5)
    80002e2e:	b7dd                	j	80002e14 <argraw+0x30>
        return p->trapframe->a4;
    80002e30:	713c                	ld	a5,96(a0)
    80002e32:	6bc8                	ld	a0,144(a5)
    80002e34:	b7c5                	j	80002e14 <argraw+0x30>
        return p->trapframe->a5;
    80002e36:	713c                	ld	a5,96(a0)
    80002e38:	6fc8                	ld	a0,152(a5)
    80002e3a:	bfe9                	j	80002e14 <argraw+0x30>
    panic("argraw");
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	6a450513          	addi	a0,a0,1700 # 800084e0 <states.0+0x148>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	6fc080e7          	jalr	1788(ra) # 80000540 <panic>

0000000080002e4c <fetchaddr>:
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	e426                	sd	s1,8(sp)
    80002e54:	e04a                	sd	s2,0(sp)
    80002e56:	1000                	addi	s0,sp,32
    80002e58:	84aa                	mv	s1,a0
    80002e5a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	d28080e7          	jalr	-728(ra) # 80001b84 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e64:	693c                	ld	a5,80(a0)
    80002e66:	02f4f863          	bgeu	s1,a5,80002e96 <fetchaddr+0x4a>
    80002e6a:	00848713          	addi	a4,s1,8
    80002e6e:	02e7e663          	bltu	a5,a4,80002e9a <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e72:	46a1                	li	a3,8
    80002e74:	8626                	mv	a2,s1
    80002e76:	85ca                	mv	a1,s2
    80002e78:	6d28                	ld	a0,88(a0)
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	87e080e7          	jalr	-1922(ra) # 800016f8 <copyin>
    80002e82:	00a03533          	snez	a0,a0
    80002e86:	40a00533          	neg	a0,a0
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6902                	ld	s2,0(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret
        return -1;
    80002e96:	557d                	li	a0,-1
    80002e98:	bfcd                	j	80002e8a <fetchaddr+0x3e>
    80002e9a:	557d                	li	a0,-1
    80002e9c:	b7fd                	j	80002e8a <fetchaddr+0x3e>

0000000080002e9e <fetchstr>:
{
    80002e9e:	7179                	addi	sp,sp,-48
    80002ea0:	f406                	sd	ra,40(sp)
    80002ea2:	f022                	sd	s0,32(sp)
    80002ea4:	ec26                	sd	s1,24(sp)
    80002ea6:	e84a                	sd	s2,16(sp)
    80002ea8:	e44e                	sd	s3,8(sp)
    80002eaa:	1800                	addi	s0,sp,48
    80002eac:	892a                	mv	s2,a0
    80002eae:	84ae                	mv	s1,a1
    80002eb0:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	cd2080e7          	jalr	-814(ra) # 80001b84 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002eba:	86ce                	mv	a3,s3
    80002ebc:	864a                	mv	a2,s2
    80002ebe:	85a6                	mv	a1,s1
    80002ec0:	6d28                	ld	a0,88(a0)
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	8c4080e7          	jalr	-1852(ra) # 80001786 <copyinstr>
    80002eca:	00054e63          	bltz	a0,80002ee6 <fetchstr+0x48>
    return strlen(buf);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	f7e080e7          	jalr	-130(ra) # 80000e4e <strlen>
}
    80002ed8:	70a2                	ld	ra,40(sp)
    80002eda:	7402                	ld	s0,32(sp)
    80002edc:	64e2                	ld	s1,24(sp)
    80002ede:	6942                	ld	s2,16(sp)
    80002ee0:	69a2                	ld	s3,8(sp)
    80002ee2:	6145                	addi	sp,sp,48
    80002ee4:	8082                	ret
        return -1;
    80002ee6:	557d                	li	a0,-1
    80002ee8:	bfc5                	j	80002ed8 <fetchstr+0x3a>

0000000080002eea <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	e426                	sd	s1,8(sp)
    80002ef2:	1000                	addi	s0,sp,32
    80002ef4:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002ef6:	00000097          	auipc	ra,0x0
    80002efa:	eee080e7          	jalr	-274(ra) # 80002de4 <argraw>
    80002efe:	c088                	sw	a0,0(s1)
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	e426                	sd	s1,8(sp)
    80002f12:	1000                	addi	s0,sp,32
    80002f14:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	ece080e7          	jalr	-306(ra) # 80002de4 <argraw>
    80002f1e:	e088                	sd	a0,0(s1)
}
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	64a2                	ld	s1,8(sp)
    80002f26:	6105                	addi	sp,sp,32
    80002f28:	8082                	ret

0000000080002f2a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002f2a:	7179                	addi	sp,sp,-48
    80002f2c:	f406                	sd	ra,40(sp)
    80002f2e:	f022                	sd	s0,32(sp)
    80002f30:	ec26                	sd	s1,24(sp)
    80002f32:	e84a                	sd	s2,16(sp)
    80002f34:	1800                	addi	s0,sp,48
    80002f36:	84ae                	mv	s1,a1
    80002f38:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002f3a:	fd840593          	addi	a1,s0,-40
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	fcc080e7          	jalr	-52(ra) # 80002f0a <argaddr>
    return fetchstr(addr, buf, max);
    80002f46:	864a                	mv	a2,s2
    80002f48:	85a6                	mv	a1,s1
    80002f4a:	fd843503          	ld	a0,-40(s0)
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	f50080e7          	jalr	-176(ra) # 80002e9e <fetchstr>
}
    80002f56:	70a2                	ld	ra,40(sp)
    80002f58:	7402                	ld	s0,32(sp)
    80002f5a:	64e2                	ld	s1,24(sp)
    80002f5c:	6942                	ld	s2,16(sp)
    80002f5e:	6145                	addi	sp,sp,48
    80002f60:	8082                	ret

0000000080002f62 <syscall>:
    [SYS_schedset] sys_schedset,
    [SYS_yield] sys_yield,
};

void syscall(void)
{
    80002f62:	1101                	addi	sp,sp,-32
    80002f64:	ec06                	sd	ra,24(sp)
    80002f66:	e822                	sd	s0,16(sp)
    80002f68:	e426                	sd	s1,8(sp)
    80002f6a:	e04a                	sd	s2,0(sp)
    80002f6c:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	c16080e7          	jalr	-1002(ra) # 80001b84 <myproc>
    80002f76:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002f78:	06053903          	ld	s2,96(a0)
    80002f7c:	0a893783          	ld	a5,168(s2)
    80002f80:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f84:	37fd                	addiw	a5,a5,-1
    80002f86:	4761                	li	a4,24
    80002f88:	00f76f63          	bltu	a4,a5,80002fa6 <syscall+0x44>
    80002f8c:	00369713          	slli	a4,a3,0x3
    80002f90:	00005797          	auipc	a5,0x5
    80002f94:	59078793          	addi	a5,a5,1424 # 80008520 <syscalls>
    80002f98:	97ba                	add	a5,a5,a4
    80002f9a:	639c                	ld	a5,0(a5)
    80002f9c:	c789                	beqz	a5,80002fa6 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002f9e:	9782                	jalr	a5
    80002fa0:	06a93823          	sd	a0,112(s2)
    80002fa4:	a839                	j	80002fc2 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002fa6:	16048613          	addi	a2,s1,352
    80002faa:	5c8c                	lw	a1,56(s1)
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	53c50513          	addi	a0,a0,1340 # 800084e8 <states.0+0x150>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	5d6080e7          	jalr	1494(ra) # 8000058a <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002fbc:	70bc                	ld	a5,96(s1)
    80002fbe:	577d                	li	a4,-1
    80002fc0:	fbb8                	sd	a4,112(a5)
    }
}
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	64a2                	ld	s1,8(sp)
    80002fc8:	6902                	ld	s2,0(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret

0000000080002fce <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fce:	1101                	addi	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002fd6:	fec40593          	addi	a1,s0,-20
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	f0e080e7          	jalr	-242(ra) # 80002eea <argint>
    exit(n);
    80002fe4:	fec42503          	lw	a0,-20(s0)
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	47e080e7          	jalr	1150(ra) # 80002466 <exit>
    return 0; // not reached
}
    80002ff0:	4501                	li	a0,0
    80002ff2:	60e2                	ld	ra,24(sp)
    80002ff4:	6442                	ld	s0,16(sp)
    80002ff6:	6105                	addi	sp,sp,32
    80002ff8:	8082                	ret

0000000080002ffa <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ffa:	1141                	addi	sp,sp,-16
    80002ffc:	e406                	sd	ra,8(sp)
    80002ffe:	e022                	sd	s0,0(sp)
    80003000:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	b82080e7          	jalr	-1150(ra) # 80001b84 <myproc>
}
    8000300a:	5d08                	lw	a0,56(a0)
    8000300c:	60a2                	ld	ra,8(sp)
    8000300e:	6402                	ld	s0,0(sp)
    80003010:	0141                	addi	sp,sp,16
    80003012:	8082                	ret

0000000080003014 <sys_fork>:

uint64
sys_fork(void)
{
    80003014:	1141                	addi	sp,sp,-16
    80003016:	e406                	sd	ra,8(sp)
    80003018:	e022                	sd	s0,0(sp)
    8000301a:	0800                	addi	s0,sp,16
    return fork();
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	0b4080e7          	jalr	180(ra) # 800020d0 <fork>
}
    80003024:	60a2                	ld	ra,8(sp)
    80003026:	6402                	ld	s0,0(sp)
    80003028:	0141                	addi	sp,sp,16
    8000302a:	8082                	ret

000000008000302c <sys_wait>:

uint64
sys_wait(void)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003034:	fe840593          	addi	a1,s0,-24
    80003038:	4501                	li	a0,0
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	ed0080e7          	jalr	-304(ra) # 80002f0a <argaddr>
    return wait(p);
    80003042:	fe843503          	ld	a0,-24(s0)
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	5c6080e7          	jalr	1478(ra) # 8000260c <wait>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003056:	7179                	addi	sp,sp,-48
    80003058:	f406                	sd	ra,40(sp)
    8000305a:	f022                	sd	s0,32(sp)
    8000305c:	ec26                	sd	s1,24(sp)
    8000305e:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003060:	fdc40593          	addi	a1,s0,-36
    80003064:	4501                	li	a0,0
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	e84080e7          	jalr	-380(ra) # 80002eea <argint>
    addr = myproc()->sz;
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	b16080e7          	jalr	-1258(ra) # 80001b84 <myproc>
    80003076:	6924                	ld	s1,80(a0)
    if (growproc(n) < 0)
    80003078:	fdc42503          	lw	a0,-36(s0)
    8000307c:	fffff097          	auipc	ra,0xfffff
    80003080:	e62080e7          	jalr	-414(ra) # 80001ede <growproc>
    80003084:	00054863          	bltz	a0,80003094 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003088:	8526                	mv	a0,s1
    8000308a:	70a2                	ld	ra,40(sp)
    8000308c:	7402                	ld	s0,32(sp)
    8000308e:	64e2                	ld	s1,24(sp)
    80003090:	6145                	addi	sp,sp,48
    80003092:	8082                	ret
        return -1;
    80003094:	54fd                	li	s1,-1
    80003096:	bfcd                	j	80003088 <sys_sbrk+0x32>

0000000080003098 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003098:	7139                	addi	sp,sp,-64
    8000309a:	fc06                	sd	ra,56(sp)
    8000309c:	f822                	sd	s0,48(sp)
    8000309e:	f426                	sd	s1,40(sp)
    800030a0:	f04a                	sd	s2,32(sp)
    800030a2:	ec4e                	sd	s3,24(sp)
    800030a4:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800030a6:	fcc40593          	addi	a1,s0,-52
    800030aa:	4501                	li	a0,0
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	e3e080e7          	jalr	-450(ra) # 80002eea <argint>
    acquire(&tickslock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	c0c50513          	addi	a0,a0,-1012 # 80016cc0 <tickslock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
    ticks0 = ticks;
    800030c4:	00006917          	auipc	s2,0x6
    800030c8:	95c92903          	lw	s2,-1700(s2) # 80008a20 <ticks>
    while (ticks - ticks0 < n)
    800030cc:	fcc42783          	lw	a5,-52(s0)
    800030d0:	cf9d                	beqz	a5,8000310e <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800030d2:	00014997          	auipc	s3,0x14
    800030d6:	bee98993          	addi	s3,s3,-1042 # 80016cc0 <tickslock>
    800030da:	00006497          	auipc	s1,0x6
    800030de:	94648493          	addi	s1,s1,-1722 # 80008a20 <ticks>
        if (killed(myproc()))
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	aa2080e7          	jalr	-1374(ra) # 80001b84 <myproc>
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	4f0080e7          	jalr	1264(ra) # 800025da <killed>
    800030f2:	ed15                	bnez	a0,8000312e <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800030f4:	85ce                	mv	a1,s3
    800030f6:	8526                	mv	a0,s1
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	23a080e7          	jalr	570(ra) # 80002332 <sleep>
    while (ticks - ticks0 < n)
    80003100:	409c                	lw	a5,0(s1)
    80003102:	412787bb          	subw	a5,a5,s2
    80003106:	fcc42703          	lw	a4,-52(s0)
    8000310a:	fce7ece3          	bltu	a5,a4,800030e2 <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	bb250513          	addi	a0,a0,-1102 # 80016cc0 <tickslock>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b74080e7          	jalr	-1164(ra) # 80000c8a <release>
    return 0;
    8000311e:	4501                	li	a0,0
}
    80003120:	70e2                	ld	ra,56(sp)
    80003122:	7442                	ld	s0,48(sp)
    80003124:	74a2                	ld	s1,40(sp)
    80003126:	7902                	ld	s2,32(sp)
    80003128:	69e2                	ld	s3,24(sp)
    8000312a:	6121                	addi	sp,sp,64
    8000312c:	8082                	ret
            release(&tickslock);
    8000312e:	00014517          	auipc	a0,0x14
    80003132:	b9250513          	addi	a0,a0,-1134 # 80016cc0 <tickslock>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	b54080e7          	jalr	-1196(ra) # 80000c8a <release>
            return -1;
    8000313e:	557d                	li	a0,-1
    80003140:	b7c5                	j	80003120 <sys_sleep+0x88>

0000000080003142 <sys_kill>:

uint64
sys_kill(void)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000314a:	fec40593          	addi	a1,s0,-20
    8000314e:	4501                	li	a0,0
    80003150:	00000097          	auipc	ra,0x0
    80003154:	d9a080e7          	jalr	-614(ra) # 80002eea <argint>
    return kill(pid);
    80003158:	fec42503          	lw	a0,-20(s0)
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	3e0080e7          	jalr	992(ra) # 8000253c <kill>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	6105                	addi	sp,sp,32
    8000316a:	8082                	ret

000000008000316c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000316c:	1101                	addi	sp,sp,-32
    8000316e:	ec06                	sd	ra,24(sp)
    80003170:	e822                	sd	s0,16(sp)
    80003172:	e426                	sd	s1,8(sp)
    80003174:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003176:	00014517          	auipc	a0,0x14
    8000317a:	b4a50513          	addi	a0,a0,-1206 # 80016cc0 <tickslock>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	a58080e7          	jalr	-1448(ra) # 80000bd6 <acquire>
    xticks = ticks;
    80003186:	00006497          	auipc	s1,0x6
    8000318a:	89a4a483          	lw	s1,-1894(s1) # 80008a20 <ticks>
    release(&tickslock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	b3250513          	addi	a0,a0,-1230 # 80016cc0 <tickslock>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	af4080e7          	jalr	-1292(ra) # 80000c8a <release>
    return xticks;
}
    8000319e:	02049513          	slli	a0,s1,0x20
    800031a2:	9101                	srli	a0,a0,0x20
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	64a2                	ld	s1,8(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <sys_ps>:

void *
sys_ps(void)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800031b6:	fe042623          	sw	zero,-20(s0)
    800031ba:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800031be:	fec40593          	addi	a1,s0,-20
    800031c2:	4501                	li	a0,0
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	d26080e7          	jalr	-730(ra) # 80002eea <argint>
    argint(1, &count);
    800031cc:	fe840593          	addi	a1,s0,-24
    800031d0:	4505                	li	a0,1
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	d18080e7          	jalr	-744(ra) # 80002eea <argint>
    return ps((uint8)start, (uint8)count);
    800031da:	fe844583          	lbu	a1,-24(s0)
    800031de:	fec44503          	lbu	a0,-20(s0)
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	d58080e7          	jalr	-680(ra) # 80001f3a <ps>
}
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <sys_schedls>:

uint64 sys_schedls(void)
{
    800031f2:	1141                	addi	sp,sp,-16
    800031f4:	e406                	sd	ra,8(sp)
    800031f6:	e022                	sd	s0,0(sp)
    800031f8:	0800                	addi	s0,sp,16
    schedls();
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	69c080e7          	jalr	1692(ra) # 80002896 <schedls>
    return 0;
}
    80003202:	4501                	li	a0,0
    80003204:	60a2                	ld	ra,8(sp)
    80003206:	6402                	ld	s0,0(sp)
    80003208:	0141                	addi	sp,sp,16
    8000320a:	8082                	ret

000000008000320c <sys_schedset>:

uint64 sys_schedset(void)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	1000                	addi	s0,sp,32
    int id = 0;
    80003214:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003218:	fec40593          	addi	a1,s0,-20
    8000321c:	4501                	li	a0,0
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	ccc080e7          	jalr	-820(ra) # 80002eea <argint>
    schedset(id - 1);
    80003226:	fec42503          	lw	a0,-20(s0)
    8000322a:	357d                	addiw	a0,a0,-1
    8000322c:	fffff097          	auipc	ra,0xfffff
    80003230:	756080e7          	jalr	1878(ra) # 80002982 <schedset>
    return 0;
}
    80003234:	4501                	li	a0,0
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	6105                	addi	sp,sp,32
    8000323c:	8082                	ret

000000008000323e <sys_yield>:

uint64 sys_yield(void)
{
    8000323e:	1141                	addi	sp,sp,-16
    80003240:	e406                	sd	ra,8(sp)
    80003242:	e022                	sd	s0,0(sp)
    80003244:	0800                	addi	s0,sp,16
    yield(YIELD_OTHER);
    80003246:	4509                	li	a0,2
    80003248:	fffff097          	auipc	ra,0xfffff
    8000324c:	0ae080e7          	jalr	174(ra) # 800022f6 <yield>
    return 0;
    80003250:	4501                	li	a0,0
    80003252:	60a2                	ld	ra,8(sp)
    80003254:	6402                	ld	s0,0(sp)
    80003256:	0141                	addi	sp,sp,16
    80003258:	8082                	ret

000000008000325a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000325a:	7179                	addi	sp,sp,-48
    8000325c:	f406                	sd	ra,40(sp)
    8000325e:	f022                	sd	s0,32(sp)
    80003260:	ec26                	sd	s1,24(sp)
    80003262:	e84a                	sd	s2,16(sp)
    80003264:	e44e                	sd	s3,8(sp)
    80003266:	e052                	sd	s4,0(sp)
    80003268:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000326a:	00005597          	auipc	a1,0x5
    8000326e:	38658593          	addi	a1,a1,902 # 800085f0 <syscalls+0xd0>
    80003272:	00014517          	auipc	a0,0x14
    80003276:	a6650513          	addi	a0,a0,-1434 # 80016cd8 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	8cc080e7          	jalr	-1844(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003282:	0001c797          	auipc	a5,0x1c
    80003286:	a5678793          	addi	a5,a5,-1450 # 8001ecd8 <bcache+0x8000>
    8000328a:	0001c717          	auipc	a4,0x1c
    8000328e:	cb670713          	addi	a4,a4,-842 # 8001ef40 <bcache+0x8268>
    80003292:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003296:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000329a:	00014497          	auipc	s1,0x14
    8000329e:	a5648493          	addi	s1,s1,-1450 # 80016cf0 <bcache+0x18>
    b->next = bcache.head.next;
    800032a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032a6:	00005a17          	auipc	s4,0x5
    800032aa:	352a0a13          	addi	s4,s4,850 # 800085f8 <syscalls+0xd8>
    b->next = bcache.head.next;
    800032ae:	2b893783          	ld	a5,696(s2)
    800032b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032b8:	85d2                	mv	a1,s4
    800032ba:	01048513          	addi	a0,s1,16
    800032be:	00001097          	auipc	ra,0x1
    800032c2:	4c8080e7          	jalr	1224(ra) # 80004786 <initsleeplock>
    bcache.head.next->prev = b;
    800032c6:	2b893783          	ld	a5,696(s2)
    800032ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032d0:	45848493          	addi	s1,s1,1112
    800032d4:	fd349de3          	bne	s1,s3,800032ae <binit+0x54>
  }
}
    800032d8:	70a2                	ld	ra,40(sp)
    800032da:	7402                	ld	s0,32(sp)
    800032dc:	64e2                	ld	s1,24(sp)
    800032de:	6942                	ld	s2,16(sp)
    800032e0:	69a2                	ld	s3,8(sp)
    800032e2:	6a02                	ld	s4,0(sp)
    800032e4:	6145                	addi	sp,sp,48
    800032e6:	8082                	ret

00000000800032e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032e8:	7179                	addi	sp,sp,-48
    800032ea:	f406                	sd	ra,40(sp)
    800032ec:	f022                	sd	s0,32(sp)
    800032ee:	ec26                	sd	s1,24(sp)
    800032f0:	e84a                	sd	s2,16(sp)
    800032f2:	e44e                	sd	s3,8(sp)
    800032f4:	1800                	addi	s0,sp,48
    800032f6:	892a                	mv	s2,a0
    800032f8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032fa:	00014517          	auipc	a0,0x14
    800032fe:	9de50513          	addi	a0,a0,-1570 # 80016cd8 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	8d4080e7          	jalr	-1836(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000330a:	0001c497          	auipc	s1,0x1c
    8000330e:	c864b483          	ld	s1,-890(s1) # 8001ef90 <bcache+0x82b8>
    80003312:	0001c797          	auipc	a5,0x1c
    80003316:	c2e78793          	addi	a5,a5,-978 # 8001ef40 <bcache+0x8268>
    8000331a:	02f48f63          	beq	s1,a5,80003358 <bread+0x70>
    8000331e:	873e                	mv	a4,a5
    80003320:	a021                	j	80003328 <bread+0x40>
    80003322:	68a4                	ld	s1,80(s1)
    80003324:	02e48a63          	beq	s1,a4,80003358 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003328:	449c                	lw	a5,8(s1)
    8000332a:	ff279ce3          	bne	a5,s2,80003322 <bread+0x3a>
    8000332e:	44dc                	lw	a5,12(s1)
    80003330:	ff3799e3          	bne	a5,s3,80003322 <bread+0x3a>
      b->refcnt++;
    80003334:	40bc                	lw	a5,64(s1)
    80003336:	2785                	addiw	a5,a5,1
    80003338:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000333a:	00014517          	auipc	a0,0x14
    8000333e:	99e50513          	addi	a0,a0,-1634 # 80016cd8 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	948080e7          	jalr	-1720(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000334a:	01048513          	addi	a0,s1,16
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	472080e7          	jalr	1138(ra) # 800047c0 <acquiresleep>
      return b;
    80003356:	a8b9                	j	800033b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003358:	0001c497          	auipc	s1,0x1c
    8000335c:	c304b483          	ld	s1,-976(s1) # 8001ef88 <bcache+0x82b0>
    80003360:	0001c797          	auipc	a5,0x1c
    80003364:	be078793          	addi	a5,a5,-1056 # 8001ef40 <bcache+0x8268>
    80003368:	00f48863          	beq	s1,a5,80003378 <bread+0x90>
    8000336c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000336e:	40bc                	lw	a5,64(s1)
    80003370:	cf81                	beqz	a5,80003388 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003372:	64a4                	ld	s1,72(s1)
    80003374:	fee49de3          	bne	s1,a4,8000336e <bread+0x86>
  panic("bget: no buffers");
    80003378:	00005517          	auipc	a0,0x5
    8000337c:	28850513          	addi	a0,a0,648 # 80008600 <syscalls+0xe0>
    80003380:	ffffd097          	auipc	ra,0xffffd
    80003384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>
      b->dev = dev;
    80003388:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000338c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003390:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003394:	4785                	li	a5,1
    80003396:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003398:	00014517          	auipc	a0,0x14
    8000339c:	94050513          	addi	a0,a0,-1728 # 80016cd8 <bcache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	8ea080e7          	jalr	-1814(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800033a8:	01048513          	addi	a0,s1,16
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	414080e7          	jalr	1044(ra) # 800047c0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033b4:	409c                	lw	a5,0(s1)
    800033b6:	cb89                	beqz	a5,800033c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033b8:	8526                	mv	a0,s1
    800033ba:	70a2                	ld	ra,40(sp)
    800033bc:	7402                	ld	s0,32(sp)
    800033be:	64e2                	ld	s1,24(sp)
    800033c0:	6942                	ld	s2,16(sp)
    800033c2:	69a2                	ld	s3,8(sp)
    800033c4:	6145                	addi	sp,sp,48
    800033c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800033c8:	4581                	li	a1,0
    800033ca:	8526                	mv	a0,s1
    800033cc:	00003097          	auipc	ra,0x3
    800033d0:	fd6080e7          	jalr	-42(ra) # 800063a2 <virtio_disk_rw>
    b->valid = 1;
    800033d4:	4785                	li	a5,1
    800033d6:	c09c                	sw	a5,0(s1)
  return b;
    800033d8:	b7c5                	j	800033b8 <bread+0xd0>

00000000800033da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e6:	0541                	addi	a0,a0,16
    800033e8:	00001097          	auipc	ra,0x1
    800033ec:	472080e7          	jalr	1138(ra) # 8000485a <holdingsleep>
    800033f0:	cd01                	beqz	a0,80003408 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033f2:	4585                	li	a1,1
    800033f4:	8526                	mv	a0,s1
    800033f6:	00003097          	auipc	ra,0x3
    800033fa:	fac080e7          	jalr	-84(ra) # 800063a2 <virtio_disk_rw>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	64a2                	ld	s1,8(sp)
    80003404:	6105                	addi	sp,sp,32
    80003406:	8082                	ret
    panic("bwrite");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	21050513          	addi	a0,a0,528 # 80008618 <syscalls+0xf8>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	130080e7          	jalr	304(ra) # 80000540 <panic>

0000000080003418 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003426:	01050913          	addi	s2,a0,16
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	42e080e7          	jalr	1070(ra) # 8000485a <holdingsleep>
    80003434:	c92d                	beqz	a0,800034a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003436:	854a                	mv	a0,s2
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	3de080e7          	jalr	990(ra) # 80004816 <releasesleep>

  acquire(&bcache.lock);
    80003440:	00014517          	auipc	a0,0x14
    80003444:	89850513          	addi	a0,a0,-1896 # 80016cd8 <bcache>
    80003448:	ffffd097          	auipc	ra,0xffffd
    8000344c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003450:	40bc                	lw	a5,64(s1)
    80003452:	37fd                	addiw	a5,a5,-1
    80003454:	0007871b          	sext.w	a4,a5
    80003458:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000345a:	eb05                	bnez	a4,8000348a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000345c:	68bc                	ld	a5,80(s1)
    8000345e:	64b8                	ld	a4,72(s1)
    80003460:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003462:	64bc                	ld	a5,72(s1)
    80003464:	68b8                	ld	a4,80(s1)
    80003466:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003468:	0001c797          	auipc	a5,0x1c
    8000346c:	87078793          	addi	a5,a5,-1936 # 8001ecd8 <bcache+0x8000>
    80003470:	2b87b703          	ld	a4,696(a5)
    80003474:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003476:	0001c717          	auipc	a4,0x1c
    8000347a:	aca70713          	addi	a4,a4,-1334 # 8001ef40 <bcache+0x8268>
    8000347e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003480:	2b87b703          	ld	a4,696(a5)
    80003484:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003486:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000348a:	00014517          	auipc	a0,0x14
    8000348e:	84e50513          	addi	a0,a0,-1970 # 80016cd8 <bcache>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	7f8080e7          	jalr	2040(ra) # 80000c8a <release>
}
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	64a2                	ld	s1,8(sp)
    800034a0:	6902                	ld	s2,0(sp)
    800034a2:	6105                	addi	sp,sp,32
    800034a4:	8082                	ret
    panic("brelse");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	17a50513          	addi	a0,a0,378 # 80008620 <syscalls+0x100>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	092080e7          	jalr	146(ra) # 80000540 <panic>

00000000800034b6 <bpin>:

void
bpin(struct buf *b) {
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c2:	00014517          	auipc	a0,0x14
    800034c6:	81650513          	addi	a0,a0,-2026 # 80016cd8 <bcache>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	70c080e7          	jalr	1804(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800034d2:	40bc                	lw	a5,64(s1)
    800034d4:	2785                	addiw	a5,a5,1
    800034d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	80050513          	addi	a0,a0,-2048 # 80016cd8 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	7aa080e7          	jalr	1962(ra) # 80000c8a <release>
}
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	64a2                	ld	s1,8(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret

00000000800034f2 <bunpin>:

void
bunpin(struct buf *b) {
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	1000                	addi	s0,sp,32
    800034fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034fe:	00013517          	auipc	a0,0x13
    80003502:	7da50513          	addi	a0,a0,2010 # 80016cd8 <bcache>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	6d0080e7          	jalr	1744(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000350e:	40bc                	lw	a5,64(s1)
    80003510:	37fd                	addiw	a5,a5,-1
    80003512:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003514:	00013517          	auipc	a0,0x13
    80003518:	7c450513          	addi	a0,a0,1988 # 80016cd8 <bcache>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	76e080e7          	jalr	1902(ra) # 80000c8a <release>
}
    80003524:	60e2                	ld	ra,24(sp)
    80003526:	6442                	ld	s0,16(sp)
    80003528:	64a2                	ld	s1,8(sp)
    8000352a:	6105                	addi	sp,sp,32
    8000352c:	8082                	ret

000000008000352e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	e426                	sd	s1,8(sp)
    80003536:	e04a                	sd	s2,0(sp)
    80003538:	1000                	addi	s0,sp,32
    8000353a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000353c:	00d5d59b          	srliw	a1,a1,0xd
    80003540:	0001c797          	auipc	a5,0x1c
    80003544:	e747a783          	lw	a5,-396(a5) # 8001f3b4 <sb+0x1c>
    80003548:	9dbd                	addw	a1,a1,a5
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	d9e080e7          	jalr	-610(ra) # 800032e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003552:	0074f713          	andi	a4,s1,7
    80003556:	4785                	li	a5,1
    80003558:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000355c:	14ce                	slli	s1,s1,0x33
    8000355e:	90d9                	srli	s1,s1,0x36
    80003560:	00950733          	add	a4,a0,s1
    80003564:	05874703          	lbu	a4,88(a4)
    80003568:	00e7f6b3          	and	a3,a5,a4
    8000356c:	c69d                	beqz	a3,8000359a <bfree+0x6c>
    8000356e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003570:	94aa                	add	s1,s1,a0
    80003572:	fff7c793          	not	a5,a5
    80003576:	8f7d                	and	a4,a4,a5
    80003578:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	126080e7          	jalr	294(ra) # 800046a2 <log_write>
  brelse(bp);
    80003584:	854a                	mv	a0,s2
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	e92080e7          	jalr	-366(ra) # 80003418 <brelse>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	64a2                	ld	s1,8(sp)
    80003594:	6902                	ld	s2,0(sp)
    80003596:	6105                	addi	sp,sp,32
    80003598:	8082                	ret
    panic("freeing free block");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	08e50513          	addi	a0,a0,142 # 80008628 <syscalls+0x108>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9e080e7          	jalr	-98(ra) # 80000540 <panic>

00000000800035aa <balloc>:
{
    800035aa:	711d                	addi	sp,sp,-96
    800035ac:	ec86                	sd	ra,88(sp)
    800035ae:	e8a2                	sd	s0,80(sp)
    800035b0:	e4a6                	sd	s1,72(sp)
    800035b2:	e0ca                	sd	s2,64(sp)
    800035b4:	fc4e                	sd	s3,56(sp)
    800035b6:	f852                	sd	s4,48(sp)
    800035b8:	f456                	sd	s5,40(sp)
    800035ba:	f05a                	sd	s6,32(sp)
    800035bc:	ec5e                	sd	s7,24(sp)
    800035be:	e862                	sd	s8,16(sp)
    800035c0:	e466                	sd	s9,8(sp)
    800035c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035c4:	0001c797          	auipc	a5,0x1c
    800035c8:	dd87a783          	lw	a5,-552(a5) # 8001f39c <sb+0x4>
    800035cc:	cff5                	beqz	a5,800036c8 <balloc+0x11e>
    800035ce:	8baa                	mv	s7,a0
    800035d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035d2:	0001cb17          	auipc	s6,0x1c
    800035d6:	dc6b0b13          	addi	s6,s6,-570 # 8001f398 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035e0:	6c89                	lui	s9,0x2
    800035e2:	a061                	j	8000366a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035e4:	97ca                	add	a5,a5,s2
    800035e6:	8e55                	or	a2,a2,a3
    800035e8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035ec:	854a                	mv	a0,s2
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	0b4080e7          	jalr	180(ra) # 800046a2 <log_write>
        brelse(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	e20080e7          	jalr	-480(ra) # 80003418 <brelse>
  bp = bread(dev, bno);
    80003600:	85a6                	mv	a1,s1
    80003602:	855e                	mv	a0,s7
    80003604:	00000097          	auipc	ra,0x0
    80003608:	ce4080e7          	jalr	-796(ra) # 800032e8 <bread>
    8000360c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000360e:	40000613          	li	a2,1024
    80003612:	4581                	li	a1,0
    80003614:	05850513          	addi	a0,a0,88
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	6ba080e7          	jalr	1722(ra) # 80000cd2 <memset>
  log_write(bp);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	080080e7          	jalr	128(ra) # 800046a2 <log_write>
  brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	dec080e7          	jalr	-532(ra) # 80003418 <brelse>
}
    80003634:	8526                	mv	a0,s1
    80003636:	60e6                	ld	ra,88(sp)
    80003638:	6446                	ld	s0,80(sp)
    8000363a:	64a6                	ld	s1,72(sp)
    8000363c:	6906                	ld	s2,64(sp)
    8000363e:	79e2                	ld	s3,56(sp)
    80003640:	7a42                	ld	s4,48(sp)
    80003642:	7aa2                	ld	s5,40(sp)
    80003644:	7b02                	ld	s6,32(sp)
    80003646:	6be2                	ld	s7,24(sp)
    80003648:	6c42                	ld	s8,16(sp)
    8000364a:	6ca2                	ld	s9,8(sp)
    8000364c:	6125                	addi	sp,sp,96
    8000364e:	8082                	ret
    brelse(bp);
    80003650:	854a                	mv	a0,s2
    80003652:	00000097          	auipc	ra,0x0
    80003656:	dc6080e7          	jalr	-570(ra) # 80003418 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000365a:	015c87bb          	addw	a5,s9,s5
    8000365e:	00078a9b          	sext.w	s5,a5
    80003662:	004b2703          	lw	a4,4(s6)
    80003666:	06eaf163          	bgeu	s5,a4,800036c8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000366a:	41fad79b          	sraiw	a5,s5,0x1f
    8000366e:	0137d79b          	srliw	a5,a5,0x13
    80003672:	015787bb          	addw	a5,a5,s5
    80003676:	40d7d79b          	sraiw	a5,a5,0xd
    8000367a:	01cb2583          	lw	a1,28(s6)
    8000367e:	9dbd                	addw	a1,a1,a5
    80003680:	855e                	mv	a0,s7
    80003682:	00000097          	auipc	ra,0x0
    80003686:	c66080e7          	jalr	-922(ra) # 800032e8 <bread>
    8000368a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368c:	004b2503          	lw	a0,4(s6)
    80003690:	000a849b          	sext.w	s1,s5
    80003694:	8762                	mv	a4,s8
    80003696:	faa4fde3          	bgeu	s1,a0,80003650 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000369a:	00777693          	andi	a3,a4,7
    8000369e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036a2:	41f7579b          	sraiw	a5,a4,0x1f
    800036a6:	01d7d79b          	srliw	a5,a5,0x1d
    800036aa:	9fb9                	addw	a5,a5,a4
    800036ac:	4037d79b          	sraiw	a5,a5,0x3
    800036b0:	00f90633          	add	a2,s2,a5
    800036b4:	05864603          	lbu	a2,88(a2)
    800036b8:	00c6f5b3          	and	a1,a3,a2
    800036bc:	d585                	beqz	a1,800035e4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036be:	2705                	addiw	a4,a4,1
    800036c0:	2485                	addiw	s1,s1,1
    800036c2:	fd471ae3          	bne	a4,s4,80003696 <balloc+0xec>
    800036c6:	b769                	j	80003650 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	f7850513          	addi	a0,a0,-136 # 80008640 <syscalls+0x120>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	eba080e7          	jalr	-326(ra) # 8000058a <printf>
  return 0;
    800036d8:	4481                	li	s1,0
    800036da:	bfa9                	j	80003634 <balloc+0x8a>

00000000800036dc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036dc:	7179                	addi	sp,sp,-48
    800036de:	f406                	sd	ra,40(sp)
    800036e0:	f022                	sd	s0,32(sp)
    800036e2:	ec26                	sd	s1,24(sp)
    800036e4:	e84a                	sd	s2,16(sp)
    800036e6:	e44e                	sd	s3,8(sp)
    800036e8:	e052                	sd	s4,0(sp)
    800036ea:	1800                	addi	s0,sp,48
    800036ec:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ee:	47ad                	li	a5,11
    800036f0:	02b7e863          	bltu	a5,a1,80003720 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036f4:	02059793          	slli	a5,a1,0x20
    800036f8:	01e7d593          	srli	a1,a5,0x1e
    800036fc:	00b504b3          	add	s1,a0,a1
    80003700:	0504a903          	lw	s2,80(s1)
    80003704:	06091e63          	bnez	s2,80003780 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003708:	4108                	lw	a0,0(a0)
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	ea0080e7          	jalr	-352(ra) # 800035aa <balloc>
    80003712:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003716:	06090563          	beqz	s2,80003780 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000371a:	0524a823          	sw	s2,80(s1)
    8000371e:	a08d                	j	80003780 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003720:	ff45849b          	addiw	s1,a1,-12
    80003724:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003728:	0ff00793          	li	a5,255
    8000372c:	08e7e563          	bltu	a5,a4,800037b6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003730:	08052903          	lw	s2,128(a0)
    80003734:	00091d63          	bnez	s2,8000374e <bmap+0x72>
      addr = balloc(ip->dev);
    80003738:	4108                	lw	a0,0(a0)
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	e70080e7          	jalr	-400(ra) # 800035aa <balloc>
    80003742:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003746:	02090d63          	beqz	s2,80003780 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000374a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000374e:	85ca                	mv	a1,s2
    80003750:	0009a503          	lw	a0,0(s3)
    80003754:	00000097          	auipc	ra,0x0
    80003758:	b94080e7          	jalr	-1132(ra) # 800032e8 <bread>
    8000375c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000375e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003762:	02049713          	slli	a4,s1,0x20
    80003766:	01e75593          	srli	a1,a4,0x1e
    8000376a:	00b784b3          	add	s1,a5,a1
    8000376e:	0004a903          	lw	s2,0(s1)
    80003772:	02090063          	beqz	s2,80003792 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003776:	8552                	mv	a0,s4
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	ca0080e7          	jalr	-864(ra) # 80003418 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003780:	854a                	mv	a0,s2
    80003782:	70a2                	ld	ra,40(sp)
    80003784:	7402                	ld	s0,32(sp)
    80003786:	64e2                	ld	s1,24(sp)
    80003788:	6942                	ld	s2,16(sp)
    8000378a:	69a2                	ld	s3,8(sp)
    8000378c:	6a02                	ld	s4,0(sp)
    8000378e:	6145                	addi	sp,sp,48
    80003790:	8082                	ret
      addr = balloc(ip->dev);
    80003792:	0009a503          	lw	a0,0(s3)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	e14080e7          	jalr	-492(ra) # 800035aa <balloc>
    8000379e:	0005091b          	sext.w	s2,a0
      if(addr){
    800037a2:	fc090ae3          	beqz	s2,80003776 <bmap+0x9a>
        a[bn] = addr;
    800037a6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037aa:	8552                	mv	a0,s4
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	ef6080e7          	jalr	-266(ra) # 800046a2 <log_write>
    800037b4:	b7c9                	j	80003776 <bmap+0x9a>
  panic("bmap: out of range");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	ea250513          	addi	a0,a0,-350 # 80008658 <syscalls+0x138>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d82080e7          	jalr	-638(ra) # 80000540 <panic>

00000000800037c6 <iget>:
{
    800037c6:	7179                	addi	sp,sp,-48
    800037c8:	f406                	sd	ra,40(sp)
    800037ca:	f022                	sd	s0,32(sp)
    800037cc:	ec26                	sd	s1,24(sp)
    800037ce:	e84a                	sd	s2,16(sp)
    800037d0:	e44e                	sd	s3,8(sp)
    800037d2:	e052                	sd	s4,0(sp)
    800037d4:	1800                	addi	s0,sp,48
    800037d6:	89aa                	mv	s3,a0
    800037d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037da:	0001c517          	auipc	a0,0x1c
    800037de:	bde50513          	addi	a0,a0,-1058 # 8001f3b8 <itable>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	3f4080e7          	jalr	1012(ra) # 80000bd6 <acquire>
  empty = 0;
    800037ea:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ec:	0001c497          	auipc	s1,0x1c
    800037f0:	be448493          	addi	s1,s1,-1052 # 8001f3d0 <itable+0x18>
    800037f4:	0001d697          	auipc	a3,0x1d
    800037f8:	66c68693          	addi	a3,a3,1644 # 80020e60 <log>
    800037fc:	a039                	j	8000380a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037fe:	02090b63          	beqz	s2,80003834 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003802:	08848493          	addi	s1,s1,136
    80003806:	02d48a63          	beq	s1,a3,8000383a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000380a:	449c                	lw	a5,8(s1)
    8000380c:	fef059e3          	blez	a5,800037fe <iget+0x38>
    80003810:	4098                	lw	a4,0(s1)
    80003812:	ff3716e3          	bne	a4,s3,800037fe <iget+0x38>
    80003816:	40d8                	lw	a4,4(s1)
    80003818:	ff4713e3          	bne	a4,s4,800037fe <iget+0x38>
      ip->ref++;
    8000381c:	2785                	addiw	a5,a5,1
    8000381e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003820:	0001c517          	auipc	a0,0x1c
    80003824:	b9850513          	addi	a0,a0,-1128 # 8001f3b8 <itable>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	462080e7          	jalr	1122(ra) # 80000c8a <release>
      return ip;
    80003830:	8926                	mv	s2,s1
    80003832:	a03d                	j	80003860 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003834:	f7f9                	bnez	a5,80003802 <iget+0x3c>
    80003836:	8926                	mv	s2,s1
    80003838:	b7e9                	j	80003802 <iget+0x3c>
  if(empty == 0)
    8000383a:	02090c63          	beqz	s2,80003872 <iget+0xac>
  ip->dev = dev;
    8000383e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003842:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003846:	4785                	li	a5,1
    80003848:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000384c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003850:	0001c517          	auipc	a0,0x1c
    80003854:	b6850513          	addi	a0,a0,-1176 # 8001f3b8 <itable>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	432080e7          	jalr	1074(ra) # 80000c8a <release>
}
    80003860:	854a                	mv	a0,s2
    80003862:	70a2                	ld	ra,40(sp)
    80003864:	7402                	ld	s0,32(sp)
    80003866:	64e2                	ld	s1,24(sp)
    80003868:	6942                	ld	s2,16(sp)
    8000386a:	69a2                	ld	s3,8(sp)
    8000386c:	6a02                	ld	s4,0(sp)
    8000386e:	6145                	addi	sp,sp,48
    80003870:	8082                	ret
    panic("iget: no inodes");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	dfe50513          	addi	a0,a0,-514 # 80008670 <syscalls+0x150>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc6080e7          	jalr	-826(ra) # 80000540 <panic>

0000000080003882 <fsinit>:
fsinit(int dev) {
    80003882:	7179                	addi	sp,sp,-48
    80003884:	f406                	sd	ra,40(sp)
    80003886:	f022                	sd	s0,32(sp)
    80003888:	ec26                	sd	s1,24(sp)
    8000388a:	e84a                	sd	s2,16(sp)
    8000388c:	e44e                	sd	s3,8(sp)
    8000388e:	1800                	addi	s0,sp,48
    80003890:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003892:	4585                	li	a1,1
    80003894:	00000097          	auipc	ra,0x0
    80003898:	a54080e7          	jalr	-1452(ra) # 800032e8 <bread>
    8000389c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000389e:	0001c997          	auipc	s3,0x1c
    800038a2:	afa98993          	addi	s3,s3,-1286 # 8001f398 <sb>
    800038a6:	02000613          	li	a2,32
    800038aa:	05850593          	addi	a1,a0,88
    800038ae:	854e                	mv	a0,s3
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	47e080e7          	jalr	1150(ra) # 80000d2e <memmove>
  brelse(bp);
    800038b8:	8526                	mv	a0,s1
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	b5e080e7          	jalr	-1186(ra) # 80003418 <brelse>
  if(sb.magic != FSMAGIC)
    800038c2:	0009a703          	lw	a4,0(s3)
    800038c6:	102037b7          	lui	a5,0x10203
    800038ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ce:	02f71263          	bne	a4,a5,800038f2 <fsinit+0x70>
  initlog(dev, &sb);
    800038d2:	0001c597          	auipc	a1,0x1c
    800038d6:	ac658593          	addi	a1,a1,-1338 # 8001f398 <sb>
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	b4a080e7          	jalr	-1206(ra) # 80004426 <initlog>
}
    800038e4:	70a2                	ld	ra,40(sp)
    800038e6:	7402                	ld	s0,32(sp)
    800038e8:	64e2                	ld	s1,24(sp)
    800038ea:	6942                	ld	s2,16(sp)
    800038ec:	69a2                	ld	s3,8(sp)
    800038ee:	6145                	addi	sp,sp,48
    800038f0:	8082                	ret
    panic("invalid file system");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	d8e50513          	addi	a0,a0,-626 # 80008680 <syscalls+0x160>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c46080e7          	jalr	-954(ra) # 80000540 <panic>

0000000080003902 <iinit>:
{
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003910:	00005597          	auipc	a1,0x5
    80003914:	d8858593          	addi	a1,a1,-632 # 80008698 <syscalls+0x178>
    80003918:	0001c517          	auipc	a0,0x1c
    8000391c:	aa050513          	addi	a0,a0,-1376 # 8001f3b8 <itable>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	226080e7          	jalr	550(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003928:	0001c497          	auipc	s1,0x1c
    8000392c:	ab848493          	addi	s1,s1,-1352 # 8001f3e0 <itable+0x28>
    80003930:	0001d997          	auipc	s3,0x1d
    80003934:	54098993          	addi	s3,s3,1344 # 80020e70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003938:	00005917          	auipc	s2,0x5
    8000393c:	d6890913          	addi	s2,s2,-664 # 800086a0 <syscalls+0x180>
    80003940:	85ca                	mv	a1,s2
    80003942:	8526                	mv	a0,s1
    80003944:	00001097          	auipc	ra,0x1
    80003948:	e42080e7          	jalr	-446(ra) # 80004786 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000394c:	08848493          	addi	s1,s1,136
    80003950:	ff3498e3          	bne	s1,s3,80003940 <iinit+0x3e>
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6145                	addi	sp,sp,48
    80003960:	8082                	ret

0000000080003962 <ialloc>:
{
    80003962:	715d                	addi	sp,sp,-80
    80003964:	e486                	sd	ra,72(sp)
    80003966:	e0a2                	sd	s0,64(sp)
    80003968:	fc26                	sd	s1,56(sp)
    8000396a:	f84a                	sd	s2,48(sp)
    8000396c:	f44e                	sd	s3,40(sp)
    8000396e:	f052                	sd	s4,32(sp)
    80003970:	ec56                	sd	s5,24(sp)
    80003972:	e85a                	sd	s6,16(sp)
    80003974:	e45e                	sd	s7,8(sp)
    80003976:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003978:	0001c717          	auipc	a4,0x1c
    8000397c:	a2c72703          	lw	a4,-1492(a4) # 8001f3a4 <sb+0xc>
    80003980:	4785                	li	a5,1
    80003982:	04e7fa63          	bgeu	a5,a4,800039d6 <ialloc+0x74>
    80003986:	8aaa                	mv	s5,a0
    80003988:	8bae                	mv	s7,a1
    8000398a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000398c:	0001ca17          	auipc	s4,0x1c
    80003990:	a0ca0a13          	addi	s4,s4,-1524 # 8001f398 <sb>
    80003994:	00048b1b          	sext.w	s6,s1
    80003998:	0044d593          	srli	a1,s1,0x4
    8000399c:	018a2783          	lw	a5,24(s4)
    800039a0:	9dbd                	addw	a1,a1,a5
    800039a2:	8556                	mv	a0,s5
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	944080e7          	jalr	-1724(ra) # 800032e8 <bread>
    800039ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039ae:	05850993          	addi	s3,a0,88
    800039b2:	00f4f793          	andi	a5,s1,15
    800039b6:	079a                	slli	a5,a5,0x6
    800039b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ba:	00099783          	lh	a5,0(s3)
    800039be:	c3a1                	beqz	a5,800039fe <ialloc+0x9c>
    brelse(bp);
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	a58080e7          	jalr	-1448(ra) # 80003418 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039c8:	0485                	addi	s1,s1,1
    800039ca:	00ca2703          	lw	a4,12(s4)
    800039ce:	0004879b          	sext.w	a5,s1
    800039d2:	fce7e1e3          	bltu	a5,a4,80003994 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	cd250513          	addi	a0,a0,-814 # 800086a8 <syscalls+0x188>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	bac080e7          	jalr	-1108(ra) # 8000058a <printf>
  return 0;
    800039e6:	4501                	li	a0,0
}
    800039e8:	60a6                	ld	ra,72(sp)
    800039ea:	6406                	ld	s0,64(sp)
    800039ec:	74e2                	ld	s1,56(sp)
    800039ee:	7942                	ld	s2,48(sp)
    800039f0:	79a2                	ld	s3,40(sp)
    800039f2:	7a02                	ld	s4,32(sp)
    800039f4:	6ae2                	ld	s5,24(sp)
    800039f6:	6b42                	ld	s6,16(sp)
    800039f8:	6ba2                	ld	s7,8(sp)
    800039fa:	6161                	addi	sp,sp,80
    800039fc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039fe:	04000613          	li	a2,64
    80003a02:	4581                	li	a1,0
    80003a04:	854e                	mv	a0,s3
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	2cc080e7          	jalr	716(ra) # 80000cd2 <memset>
      dip->type = type;
    80003a0e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	c8e080e7          	jalr	-882(ra) # 800046a2 <log_write>
      brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	9fa080e7          	jalr	-1542(ra) # 80003418 <brelse>
      return iget(dev, inum);
    80003a26:	85da                	mv	a1,s6
    80003a28:	8556                	mv	a0,s5
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	d9c080e7          	jalr	-612(ra) # 800037c6 <iget>
    80003a32:	bf5d                	j	800039e8 <ialloc+0x86>

0000000080003a34 <iupdate>:
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	e04a                	sd	s2,0(sp)
    80003a3e:	1000                	addi	s0,sp,32
    80003a40:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a42:	415c                	lw	a5,4(a0)
    80003a44:	0047d79b          	srliw	a5,a5,0x4
    80003a48:	0001c597          	auipc	a1,0x1c
    80003a4c:	9685a583          	lw	a1,-1688(a1) # 8001f3b0 <sb+0x18>
    80003a50:	9dbd                	addw	a1,a1,a5
    80003a52:	4108                	lw	a0,0(a0)
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	894080e7          	jalr	-1900(ra) # 800032e8 <bread>
    80003a5c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a5e:	05850793          	addi	a5,a0,88
    80003a62:	40d8                	lw	a4,4(s1)
    80003a64:	8b3d                	andi	a4,a4,15
    80003a66:	071a                	slli	a4,a4,0x6
    80003a68:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a6a:	04449703          	lh	a4,68(s1)
    80003a6e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a72:	04649703          	lh	a4,70(s1)
    80003a76:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a7a:	04849703          	lh	a4,72(s1)
    80003a7e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a82:	04a49703          	lh	a4,74(s1)
    80003a86:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a8a:	44f8                	lw	a4,76(s1)
    80003a8c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a8e:	03400613          	li	a2,52
    80003a92:	05048593          	addi	a1,s1,80
    80003a96:	00c78513          	addi	a0,a5,12
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	294080e7          	jalr	660(ra) # 80000d2e <memmove>
  log_write(bp);
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	00001097          	auipc	ra,0x1
    80003aa8:	bfe080e7          	jalr	-1026(ra) # 800046a2 <log_write>
  brelse(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	96a080e7          	jalr	-1686(ra) # 80003418 <brelse>
}
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6902                	ld	s2,0(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret

0000000080003ac2 <idup>:
{
    80003ac2:	1101                	addi	sp,sp,-32
    80003ac4:	ec06                	sd	ra,24(sp)
    80003ac6:	e822                	sd	s0,16(sp)
    80003ac8:	e426                	sd	s1,8(sp)
    80003aca:	1000                	addi	s0,sp,32
    80003acc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ace:	0001c517          	auipc	a0,0x1c
    80003ad2:	8ea50513          	addi	a0,a0,-1814 # 8001f3b8 <itable>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	100080e7          	jalr	256(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003ade:	449c                	lw	a5,8(s1)
    80003ae0:	2785                	addiw	a5,a5,1
    80003ae2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ae4:	0001c517          	auipc	a0,0x1c
    80003ae8:	8d450513          	addi	a0,a0,-1836 # 8001f3b8 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	19e080e7          	jalr	414(ra) # 80000c8a <release>
}
    80003af4:	8526                	mv	a0,s1
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	64a2                	ld	s1,8(sp)
    80003afc:	6105                	addi	sp,sp,32
    80003afe:	8082                	ret

0000000080003b00 <ilock>:
{
    80003b00:	1101                	addi	sp,sp,-32
    80003b02:	ec06                	sd	ra,24(sp)
    80003b04:	e822                	sd	s0,16(sp)
    80003b06:	e426                	sd	s1,8(sp)
    80003b08:	e04a                	sd	s2,0(sp)
    80003b0a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b0c:	c115                	beqz	a0,80003b30 <ilock+0x30>
    80003b0e:	84aa                	mv	s1,a0
    80003b10:	451c                	lw	a5,8(a0)
    80003b12:	00f05f63          	blez	a5,80003b30 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b16:	0541                	addi	a0,a0,16
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	ca8080e7          	jalr	-856(ra) # 800047c0 <acquiresleep>
  if(ip->valid == 0){
    80003b20:	40bc                	lw	a5,64(s1)
    80003b22:	cf99                	beqz	a5,80003b40 <ilock+0x40>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6902                	ld	s2,0(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret
    panic("ilock");
    80003b30:	00005517          	auipc	a0,0x5
    80003b34:	b9050513          	addi	a0,a0,-1136 # 800086c0 <syscalls+0x1a0>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	a08080e7          	jalr	-1528(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b40:	40dc                	lw	a5,4(s1)
    80003b42:	0047d79b          	srliw	a5,a5,0x4
    80003b46:	0001c597          	auipc	a1,0x1c
    80003b4a:	86a5a583          	lw	a1,-1942(a1) # 8001f3b0 <sb+0x18>
    80003b4e:	9dbd                	addw	a1,a1,a5
    80003b50:	4088                	lw	a0,0(s1)
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	796080e7          	jalr	1942(ra) # 800032e8 <bread>
    80003b5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b5c:	05850593          	addi	a1,a0,88
    80003b60:	40dc                	lw	a5,4(s1)
    80003b62:	8bbd                	andi	a5,a5,15
    80003b64:	079a                	slli	a5,a5,0x6
    80003b66:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b68:	00059783          	lh	a5,0(a1)
    80003b6c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b70:	00259783          	lh	a5,2(a1)
    80003b74:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b78:	00459783          	lh	a5,4(a1)
    80003b7c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b80:	00659783          	lh	a5,6(a1)
    80003b84:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b88:	459c                	lw	a5,8(a1)
    80003b8a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b8c:	03400613          	li	a2,52
    80003b90:	05b1                	addi	a1,a1,12
    80003b92:	05048513          	addi	a0,s1,80
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	198080e7          	jalr	408(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	878080e7          	jalr	-1928(ra) # 80003418 <brelse>
    ip->valid = 1;
    80003ba8:	4785                	li	a5,1
    80003baa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bac:	04449783          	lh	a5,68(s1)
    80003bb0:	fbb5                	bnez	a5,80003b24 <ilock+0x24>
      panic("ilock: no type");
    80003bb2:	00005517          	auipc	a0,0x5
    80003bb6:	b1650513          	addi	a0,a0,-1258 # 800086c8 <syscalls+0x1a8>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	986080e7          	jalr	-1658(ra) # 80000540 <panic>

0000000080003bc2 <iunlock>:
{
    80003bc2:	1101                	addi	sp,sp,-32
    80003bc4:	ec06                	sd	ra,24(sp)
    80003bc6:	e822                	sd	s0,16(sp)
    80003bc8:	e426                	sd	s1,8(sp)
    80003bca:	e04a                	sd	s2,0(sp)
    80003bcc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bce:	c905                	beqz	a0,80003bfe <iunlock+0x3c>
    80003bd0:	84aa                	mv	s1,a0
    80003bd2:	01050913          	addi	s2,a0,16
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	c82080e7          	jalr	-894(ra) # 8000485a <holdingsleep>
    80003be0:	cd19                	beqz	a0,80003bfe <iunlock+0x3c>
    80003be2:	449c                	lw	a5,8(s1)
    80003be4:	00f05d63          	blez	a5,80003bfe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003be8:	854a                	mv	a0,s2
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	c2c080e7          	jalr	-980(ra) # 80004816 <releasesleep>
}
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	64a2                	ld	s1,8(sp)
    80003bf8:	6902                	ld	s2,0(sp)
    80003bfa:	6105                	addi	sp,sp,32
    80003bfc:	8082                	ret
    panic("iunlock");
    80003bfe:	00005517          	auipc	a0,0x5
    80003c02:	ada50513          	addi	a0,a0,-1318 # 800086d8 <syscalls+0x1b8>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	93a080e7          	jalr	-1734(ra) # 80000540 <panic>

0000000080003c0e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c0e:	7179                	addi	sp,sp,-48
    80003c10:	f406                	sd	ra,40(sp)
    80003c12:	f022                	sd	s0,32(sp)
    80003c14:	ec26                	sd	s1,24(sp)
    80003c16:	e84a                	sd	s2,16(sp)
    80003c18:	e44e                	sd	s3,8(sp)
    80003c1a:	e052                	sd	s4,0(sp)
    80003c1c:	1800                	addi	s0,sp,48
    80003c1e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c20:	05050493          	addi	s1,a0,80
    80003c24:	08050913          	addi	s2,a0,128
    80003c28:	a021                	j	80003c30 <itrunc+0x22>
    80003c2a:	0491                	addi	s1,s1,4
    80003c2c:	01248d63          	beq	s1,s2,80003c46 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c30:	408c                	lw	a1,0(s1)
    80003c32:	dde5                	beqz	a1,80003c2a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c34:	0009a503          	lw	a0,0(s3)
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	8f6080e7          	jalr	-1802(ra) # 8000352e <bfree>
      ip->addrs[i] = 0;
    80003c40:	0004a023          	sw	zero,0(s1)
    80003c44:	b7dd                	j	80003c2a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c46:	0809a583          	lw	a1,128(s3)
    80003c4a:	e185                	bnez	a1,80003c6a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c4c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c50:	854e                	mv	a0,s3
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	de2080e7          	jalr	-542(ra) # 80003a34 <iupdate>
}
    80003c5a:	70a2                	ld	ra,40(sp)
    80003c5c:	7402                	ld	s0,32(sp)
    80003c5e:	64e2                	ld	s1,24(sp)
    80003c60:	6942                	ld	s2,16(sp)
    80003c62:	69a2                	ld	s3,8(sp)
    80003c64:	6a02                	ld	s4,0(sp)
    80003c66:	6145                	addi	sp,sp,48
    80003c68:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c6a:	0009a503          	lw	a0,0(s3)
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	67a080e7          	jalr	1658(ra) # 800032e8 <bread>
    80003c76:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c78:	05850493          	addi	s1,a0,88
    80003c7c:	45850913          	addi	s2,a0,1112
    80003c80:	a021                	j	80003c88 <itrunc+0x7a>
    80003c82:	0491                	addi	s1,s1,4
    80003c84:	01248b63          	beq	s1,s2,80003c9a <itrunc+0x8c>
      if(a[j])
    80003c88:	408c                	lw	a1,0(s1)
    80003c8a:	dde5                	beqz	a1,80003c82 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c8c:	0009a503          	lw	a0,0(s3)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	89e080e7          	jalr	-1890(ra) # 8000352e <bfree>
    80003c98:	b7ed                	j	80003c82 <itrunc+0x74>
    brelse(bp);
    80003c9a:	8552                	mv	a0,s4
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	77c080e7          	jalr	1916(ra) # 80003418 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ca4:	0809a583          	lw	a1,128(s3)
    80003ca8:	0009a503          	lw	a0,0(s3)
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	882080e7          	jalr	-1918(ra) # 8000352e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cb4:	0809a023          	sw	zero,128(s3)
    80003cb8:	bf51                	j	80003c4c <itrunc+0x3e>

0000000080003cba <iput>:
{
    80003cba:	1101                	addi	sp,sp,-32
    80003cbc:	ec06                	sd	ra,24(sp)
    80003cbe:	e822                	sd	s0,16(sp)
    80003cc0:	e426                	sd	s1,8(sp)
    80003cc2:	e04a                	sd	s2,0(sp)
    80003cc4:	1000                	addi	s0,sp,32
    80003cc6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cc8:	0001b517          	auipc	a0,0x1b
    80003ccc:	6f050513          	addi	a0,a0,1776 # 8001f3b8 <itable>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	f06080e7          	jalr	-250(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cd8:	4498                	lw	a4,8(s1)
    80003cda:	4785                	li	a5,1
    80003cdc:	02f70363          	beq	a4,a5,80003d02 <iput+0x48>
  ip->ref--;
    80003ce0:	449c                	lw	a5,8(s1)
    80003ce2:	37fd                	addiw	a5,a5,-1
    80003ce4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ce6:	0001b517          	auipc	a0,0x1b
    80003cea:	6d250513          	addi	a0,a0,1746 # 8001f3b8 <itable>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	f9c080e7          	jalr	-100(ra) # 80000c8a <release>
}
    80003cf6:	60e2                	ld	ra,24(sp)
    80003cf8:	6442                	ld	s0,16(sp)
    80003cfa:	64a2                	ld	s1,8(sp)
    80003cfc:	6902                	ld	s2,0(sp)
    80003cfe:	6105                	addi	sp,sp,32
    80003d00:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d02:	40bc                	lw	a5,64(s1)
    80003d04:	dff1                	beqz	a5,80003ce0 <iput+0x26>
    80003d06:	04a49783          	lh	a5,74(s1)
    80003d0a:	fbf9                	bnez	a5,80003ce0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d0c:	01048913          	addi	s2,s1,16
    80003d10:	854a                	mv	a0,s2
    80003d12:	00001097          	auipc	ra,0x1
    80003d16:	aae080e7          	jalr	-1362(ra) # 800047c0 <acquiresleep>
    release(&itable.lock);
    80003d1a:	0001b517          	auipc	a0,0x1b
    80003d1e:	69e50513          	addi	a0,a0,1694 # 8001f3b8 <itable>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	f68080e7          	jalr	-152(ra) # 80000c8a <release>
    itrunc(ip);
    80003d2a:	8526                	mv	a0,s1
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	ee2080e7          	jalr	-286(ra) # 80003c0e <itrunc>
    ip->type = 0;
    80003d34:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d38:	8526                	mv	a0,s1
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	cfa080e7          	jalr	-774(ra) # 80003a34 <iupdate>
    ip->valid = 0;
    80003d42:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d46:	854a                	mv	a0,s2
    80003d48:	00001097          	auipc	ra,0x1
    80003d4c:	ace080e7          	jalr	-1330(ra) # 80004816 <releasesleep>
    acquire(&itable.lock);
    80003d50:	0001b517          	auipc	a0,0x1b
    80003d54:	66850513          	addi	a0,a0,1640 # 8001f3b8 <itable>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	e7e080e7          	jalr	-386(ra) # 80000bd6 <acquire>
    80003d60:	b741                	j	80003ce0 <iput+0x26>

0000000080003d62 <iunlockput>:
{
    80003d62:	1101                	addi	sp,sp,-32
    80003d64:	ec06                	sd	ra,24(sp)
    80003d66:	e822                	sd	s0,16(sp)
    80003d68:	e426                	sd	s1,8(sp)
    80003d6a:	1000                	addi	s0,sp,32
    80003d6c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	e54080e7          	jalr	-428(ra) # 80003bc2 <iunlock>
  iput(ip);
    80003d76:	8526                	mv	a0,s1
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	f42080e7          	jalr	-190(ra) # 80003cba <iput>
}
    80003d80:	60e2                	ld	ra,24(sp)
    80003d82:	6442                	ld	s0,16(sp)
    80003d84:	64a2                	ld	s1,8(sp)
    80003d86:	6105                	addi	sp,sp,32
    80003d88:	8082                	ret

0000000080003d8a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d8a:	1141                	addi	sp,sp,-16
    80003d8c:	e422                	sd	s0,8(sp)
    80003d8e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d90:	411c                	lw	a5,0(a0)
    80003d92:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d94:	415c                	lw	a5,4(a0)
    80003d96:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d98:	04451783          	lh	a5,68(a0)
    80003d9c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003da0:	04a51783          	lh	a5,74(a0)
    80003da4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003da8:	04c56783          	lwu	a5,76(a0)
    80003dac:	e99c                	sd	a5,16(a1)
}
    80003dae:	6422                	ld	s0,8(sp)
    80003db0:	0141                	addi	sp,sp,16
    80003db2:	8082                	ret

0000000080003db4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003db4:	457c                	lw	a5,76(a0)
    80003db6:	0ed7e963          	bltu	a5,a3,80003ea8 <readi+0xf4>
{
    80003dba:	7159                	addi	sp,sp,-112
    80003dbc:	f486                	sd	ra,104(sp)
    80003dbe:	f0a2                	sd	s0,96(sp)
    80003dc0:	eca6                	sd	s1,88(sp)
    80003dc2:	e8ca                	sd	s2,80(sp)
    80003dc4:	e4ce                	sd	s3,72(sp)
    80003dc6:	e0d2                	sd	s4,64(sp)
    80003dc8:	fc56                	sd	s5,56(sp)
    80003dca:	f85a                	sd	s6,48(sp)
    80003dcc:	f45e                	sd	s7,40(sp)
    80003dce:	f062                	sd	s8,32(sp)
    80003dd0:	ec66                	sd	s9,24(sp)
    80003dd2:	e86a                	sd	s10,16(sp)
    80003dd4:	e46e                	sd	s11,8(sp)
    80003dd6:	1880                	addi	s0,sp,112
    80003dd8:	8b2a                	mv	s6,a0
    80003dda:	8bae                	mv	s7,a1
    80003ddc:	8a32                	mv	s4,a2
    80003dde:	84b6                	mv	s1,a3
    80003de0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003de2:	9f35                	addw	a4,a4,a3
    return 0;
    80003de4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003de6:	0ad76063          	bltu	a4,a3,80003e86 <readi+0xd2>
  if(off + n > ip->size)
    80003dea:	00e7f463          	bgeu	a5,a4,80003df2 <readi+0x3e>
    n = ip->size - off;
    80003dee:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df2:	0a0a8963          	beqz	s5,80003ea4 <readi+0xf0>
    80003df6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003df8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dfc:	5c7d                	li	s8,-1
    80003dfe:	a82d                	j	80003e38 <readi+0x84>
    80003e00:	020d1d93          	slli	s11,s10,0x20
    80003e04:	020ddd93          	srli	s11,s11,0x20
    80003e08:	05890613          	addi	a2,s2,88
    80003e0c:	86ee                	mv	a3,s11
    80003e0e:	963a                	add	a2,a2,a4
    80003e10:	85d2                	mv	a1,s4
    80003e12:	855e                	mv	a0,s7
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	926080e7          	jalr	-1754(ra) # 8000273a <either_copyout>
    80003e1c:	05850d63          	beq	a0,s8,80003e76 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e20:	854a                	mv	a0,s2
    80003e22:	fffff097          	auipc	ra,0xfffff
    80003e26:	5f6080e7          	jalr	1526(ra) # 80003418 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e2a:	013d09bb          	addw	s3,s10,s3
    80003e2e:	009d04bb          	addw	s1,s10,s1
    80003e32:	9a6e                	add	s4,s4,s11
    80003e34:	0559f763          	bgeu	s3,s5,80003e82 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e38:	00a4d59b          	srliw	a1,s1,0xa
    80003e3c:	855a                	mv	a0,s6
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	89e080e7          	jalr	-1890(ra) # 800036dc <bmap>
    80003e46:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e4a:	cd85                	beqz	a1,80003e82 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e4c:	000b2503          	lw	a0,0(s6)
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	498080e7          	jalr	1176(ra) # 800032e8 <bread>
    80003e58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5a:	3ff4f713          	andi	a4,s1,1023
    80003e5e:	40ec87bb          	subw	a5,s9,a4
    80003e62:	413a86bb          	subw	a3,s5,s3
    80003e66:	8d3e                	mv	s10,a5
    80003e68:	2781                	sext.w	a5,a5
    80003e6a:	0006861b          	sext.w	a2,a3
    80003e6e:	f8f679e3          	bgeu	a2,a5,80003e00 <readi+0x4c>
    80003e72:	8d36                	mv	s10,a3
    80003e74:	b771                	j	80003e00 <readi+0x4c>
      brelse(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	5a0080e7          	jalr	1440(ra) # 80003418 <brelse>
      tot = -1;
    80003e80:	59fd                	li	s3,-1
  }
  return tot;
    80003e82:	0009851b          	sext.w	a0,s3
}
    80003e86:	70a6                	ld	ra,104(sp)
    80003e88:	7406                	ld	s0,96(sp)
    80003e8a:	64e6                	ld	s1,88(sp)
    80003e8c:	6946                	ld	s2,80(sp)
    80003e8e:	69a6                	ld	s3,72(sp)
    80003e90:	6a06                	ld	s4,64(sp)
    80003e92:	7ae2                	ld	s5,56(sp)
    80003e94:	7b42                	ld	s6,48(sp)
    80003e96:	7ba2                	ld	s7,40(sp)
    80003e98:	7c02                	ld	s8,32(sp)
    80003e9a:	6ce2                	ld	s9,24(sp)
    80003e9c:	6d42                	ld	s10,16(sp)
    80003e9e:	6da2                	ld	s11,8(sp)
    80003ea0:	6165                	addi	sp,sp,112
    80003ea2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea4:	89d6                	mv	s3,s5
    80003ea6:	bff1                	j	80003e82 <readi+0xce>
    return 0;
    80003ea8:	4501                	li	a0,0
}
    80003eaa:	8082                	ret

0000000080003eac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eac:	457c                	lw	a5,76(a0)
    80003eae:	10d7e863          	bltu	a5,a3,80003fbe <writei+0x112>
{
    80003eb2:	7159                	addi	sp,sp,-112
    80003eb4:	f486                	sd	ra,104(sp)
    80003eb6:	f0a2                	sd	s0,96(sp)
    80003eb8:	eca6                	sd	s1,88(sp)
    80003eba:	e8ca                	sd	s2,80(sp)
    80003ebc:	e4ce                	sd	s3,72(sp)
    80003ebe:	e0d2                	sd	s4,64(sp)
    80003ec0:	fc56                	sd	s5,56(sp)
    80003ec2:	f85a                	sd	s6,48(sp)
    80003ec4:	f45e                	sd	s7,40(sp)
    80003ec6:	f062                	sd	s8,32(sp)
    80003ec8:	ec66                	sd	s9,24(sp)
    80003eca:	e86a                	sd	s10,16(sp)
    80003ecc:	e46e                	sd	s11,8(sp)
    80003ece:	1880                	addi	s0,sp,112
    80003ed0:	8aaa                	mv	s5,a0
    80003ed2:	8bae                	mv	s7,a1
    80003ed4:	8a32                	mv	s4,a2
    80003ed6:	8936                	mv	s2,a3
    80003ed8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eda:	00e687bb          	addw	a5,a3,a4
    80003ede:	0ed7e263          	bltu	a5,a3,80003fc2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ee2:	00043737          	lui	a4,0x43
    80003ee6:	0ef76063          	bltu	a4,a5,80003fc6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eea:	0c0b0863          	beqz	s6,80003fba <writei+0x10e>
    80003eee:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ef4:	5c7d                	li	s8,-1
    80003ef6:	a091                	j	80003f3a <writei+0x8e>
    80003ef8:	020d1d93          	slli	s11,s10,0x20
    80003efc:	020ddd93          	srli	s11,s11,0x20
    80003f00:	05848513          	addi	a0,s1,88
    80003f04:	86ee                	mv	a3,s11
    80003f06:	8652                	mv	a2,s4
    80003f08:	85de                	mv	a1,s7
    80003f0a:	953a                	add	a0,a0,a4
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	884080e7          	jalr	-1916(ra) # 80002790 <either_copyin>
    80003f14:	07850263          	beq	a0,s8,80003f78 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f18:	8526                	mv	a0,s1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	788080e7          	jalr	1928(ra) # 800046a2 <log_write>
    brelse(bp);
    80003f22:	8526                	mv	a0,s1
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	4f4080e7          	jalr	1268(ra) # 80003418 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2c:	013d09bb          	addw	s3,s10,s3
    80003f30:	012d093b          	addw	s2,s10,s2
    80003f34:	9a6e                	add	s4,s4,s11
    80003f36:	0569f663          	bgeu	s3,s6,80003f82 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f3a:	00a9559b          	srliw	a1,s2,0xa
    80003f3e:	8556                	mv	a0,s5
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	79c080e7          	jalr	1948(ra) # 800036dc <bmap>
    80003f48:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f4c:	c99d                	beqz	a1,80003f82 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f4e:	000aa503          	lw	a0,0(s5)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	396080e7          	jalr	918(ra) # 800032e8 <bread>
    80003f5a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f5c:	3ff97713          	andi	a4,s2,1023
    80003f60:	40ec87bb          	subw	a5,s9,a4
    80003f64:	413b06bb          	subw	a3,s6,s3
    80003f68:	8d3e                	mv	s10,a5
    80003f6a:	2781                	sext.w	a5,a5
    80003f6c:	0006861b          	sext.w	a2,a3
    80003f70:	f8f674e3          	bgeu	a2,a5,80003ef8 <writei+0x4c>
    80003f74:	8d36                	mv	s10,a3
    80003f76:	b749                	j	80003ef8 <writei+0x4c>
      brelse(bp);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	49e080e7          	jalr	1182(ra) # 80003418 <brelse>
  }

  if(off > ip->size)
    80003f82:	04caa783          	lw	a5,76(s5)
    80003f86:	0127f463          	bgeu	a5,s2,80003f8e <writei+0xe2>
    ip->size = off;
    80003f8a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f8e:	8556                	mv	a0,s5
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	aa4080e7          	jalr	-1372(ra) # 80003a34 <iupdate>

  return tot;
    80003f98:	0009851b          	sext.w	a0,s3
}
    80003f9c:	70a6                	ld	ra,104(sp)
    80003f9e:	7406                	ld	s0,96(sp)
    80003fa0:	64e6                	ld	s1,88(sp)
    80003fa2:	6946                	ld	s2,80(sp)
    80003fa4:	69a6                	ld	s3,72(sp)
    80003fa6:	6a06                	ld	s4,64(sp)
    80003fa8:	7ae2                	ld	s5,56(sp)
    80003faa:	7b42                	ld	s6,48(sp)
    80003fac:	7ba2                	ld	s7,40(sp)
    80003fae:	7c02                	ld	s8,32(sp)
    80003fb0:	6ce2                	ld	s9,24(sp)
    80003fb2:	6d42                	ld	s10,16(sp)
    80003fb4:	6da2                	ld	s11,8(sp)
    80003fb6:	6165                	addi	sp,sp,112
    80003fb8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fba:	89da                	mv	s3,s6
    80003fbc:	bfc9                	j	80003f8e <writei+0xe2>
    return -1;
    80003fbe:	557d                	li	a0,-1
}
    80003fc0:	8082                	ret
    return -1;
    80003fc2:	557d                	li	a0,-1
    80003fc4:	bfe1                	j	80003f9c <writei+0xf0>
    return -1;
    80003fc6:	557d                	li	a0,-1
    80003fc8:	bfd1                	j	80003f9c <writei+0xf0>

0000000080003fca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fca:	1141                	addi	sp,sp,-16
    80003fcc:	e406                	sd	ra,8(sp)
    80003fce:	e022                	sd	s0,0(sp)
    80003fd0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fd2:	4639                	li	a2,14
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	dce080e7          	jalr	-562(ra) # 80000da2 <strncmp>
}
    80003fdc:	60a2                	ld	ra,8(sp)
    80003fde:	6402                	ld	s0,0(sp)
    80003fe0:	0141                	addi	sp,sp,16
    80003fe2:	8082                	ret

0000000080003fe4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fe4:	7139                	addi	sp,sp,-64
    80003fe6:	fc06                	sd	ra,56(sp)
    80003fe8:	f822                	sd	s0,48(sp)
    80003fea:	f426                	sd	s1,40(sp)
    80003fec:	f04a                	sd	s2,32(sp)
    80003fee:	ec4e                	sd	s3,24(sp)
    80003ff0:	e852                	sd	s4,16(sp)
    80003ff2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ff4:	04451703          	lh	a4,68(a0)
    80003ff8:	4785                	li	a5,1
    80003ffa:	00f71a63          	bne	a4,a5,8000400e <dirlookup+0x2a>
    80003ffe:	892a                	mv	s2,a0
    80004000:	89ae                	mv	s3,a1
    80004002:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004004:	457c                	lw	a5,76(a0)
    80004006:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004008:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400a:	e79d                	bnez	a5,80004038 <dirlookup+0x54>
    8000400c:	a8a5                	j	80004084 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000400e:	00004517          	auipc	a0,0x4
    80004012:	6d250513          	addi	a0,a0,1746 # 800086e0 <syscalls+0x1c0>
    80004016:	ffffc097          	auipc	ra,0xffffc
    8000401a:	52a080e7          	jalr	1322(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000401e:	00004517          	auipc	a0,0x4
    80004022:	6da50513          	addi	a0,a0,1754 # 800086f8 <syscalls+0x1d8>
    80004026:	ffffc097          	auipc	ra,0xffffc
    8000402a:	51a080e7          	jalr	1306(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000402e:	24c1                	addiw	s1,s1,16
    80004030:	04c92783          	lw	a5,76(s2)
    80004034:	04f4f763          	bgeu	s1,a5,80004082 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004038:	4741                	li	a4,16
    8000403a:	86a6                	mv	a3,s1
    8000403c:	fc040613          	addi	a2,s0,-64
    80004040:	4581                	li	a1,0
    80004042:	854a                	mv	a0,s2
    80004044:	00000097          	auipc	ra,0x0
    80004048:	d70080e7          	jalr	-656(ra) # 80003db4 <readi>
    8000404c:	47c1                	li	a5,16
    8000404e:	fcf518e3          	bne	a0,a5,8000401e <dirlookup+0x3a>
    if(de.inum == 0)
    80004052:	fc045783          	lhu	a5,-64(s0)
    80004056:	dfe1                	beqz	a5,8000402e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004058:	fc240593          	addi	a1,s0,-62
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	f6c080e7          	jalr	-148(ra) # 80003fca <namecmp>
    80004066:	f561                	bnez	a0,8000402e <dirlookup+0x4a>
      if(poff)
    80004068:	000a0463          	beqz	s4,80004070 <dirlookup+0x8c>
        *poff = off;
    8000406c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004070:	fc045583          	lhu	a1,-64(s0)
    80004074:	00092503          	lw	a0,0(s2)
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	74e080e7          	jalr	1870(ra) # 800037c6 <iget>
    80004080:	a011                	j	80004084 <dirlookup+0xa0>
  return 0;
    80004082:	4501                	li	a0,0
}
    80004084:	70e2                	ld	ra,56(sp)
    80004086:	7442                	ld	s0,48(sp)
    80004088:	74a2                	ld	s1,40(sp)
    8000408a:	7902                	ld	s2,32(sp)
    8000408c:	69e2                	ld	s3,24(sp)
    8000408e:	6a42                	ld	s4,16(sp)
    80004090:	6121                	addi	sp,sp,64
    80004092:	8082                	ret

0000000080004094 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004094:	711d                	addi	sp,sp,-96
    80004096:	ec86                	sd	ra,88(sp)
    80004098:	e8a2                	sd	s0,80(sp)
    8000409a:	e4a6                	sd	s1,72(sp)
    8000409c:	e0ca                	sd	s2,64(sp)
    8000409e:	fc4e                	sd	s3,56(sp)
    800040a0:	f852                	sd	s4,48(sp)
    800040a2:	f456                	sd	s5,40(sp)
    800040a4:	f05a                	sd	s6,32(sp)
    800040a6:	ec5e                	sd	s7,24(sp)
    800040a8:	e862                	sd	s8,16(sp)
    800040aa:	e466                	sd	s9,8(sp)
    800040ac:	e06a                	sd	s10,0(sp)
    800040ae:	1080                	addi	s0,sp,96
    800040b0:	84aa                	mv	s1,a0
    800040b2:	8b2e                	mv	s6,a1
    800040b4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040b6:	00054703          	lbu	a4,0(a0)
    800040ba:	02f00793          	li	a5,47
    800040be:	02f70363          	beq	a4,a5,800040e4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040c2:	ffffe097          	auipc	ra,0xffffe
    800040c6:	ac2080e7          	jalr	-1342(ra) # 80001b84 <myproc>
    800040ca:	15853503          	ld	a0,344(a0)
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	9f4080e7          	jalr	-1548(ra) # 80003ac2 <idup>
    800040d6:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040d8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040dc:	4cb5                	li	s9,13
  len = path - s;
    800040de:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e0:	4c05                	li	s8,1
    800040e2:	a87d                	j	800041a0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040e4:	4585                	li	a1,1
    800040e6:	4505                	li	a0,1
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	6de080e7          	jalr	1758(ra) # 800037c6 <iget>
    800040f0:	8a2a                	mv	s4,a0
    800040f2:	b7dd                	j	800040d8 <namex+0x44>
      iunlockput(ip);
    800040f4:	8552                	mv	a0,s4
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	c6c080e7          	jalr	-916(ra) # 80003d62 <iunlockput>
      return 0;
    800040fe:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004100:	8552                	mv	a0,s4
    80004102:	60e6                	ld	ra,88(sp)
    80004104:	6446                	ld	s0,80(sp)
    80004106:	64a6                	ld	s1,72(sp)
    80004108:	6906                	ld	s2,64(sp)
    8000410a:	79e2                	ld	s3,56(sp)
    8000410c:	7a42                	ld	s4,48(sp)
    8000410e:	7aa2                	ld	s5,40(sp)
    80004110:	7b02                	ld	s6,32(sp)
    80004112:	6be2                	ld	s7,24(sp)
    80004114:	6c42                	ld	s8,16(sp)
    80004116:	6ca2                	ld	s9,8(sp)
    80004118:	6d02                	ld	s10,0(sp)
    8000411a:	6125                	addi	sp,sp,96
    8000411c:	8082                	ret
      iunlock(ip);
    8000411e:	8552                	mv	a0,s4
    80004120:	00000097          	auipc	ra,0x0
    80004124:	aa2080e7          	jalr	-1374(ra) # 80003bc2 <iunlock>
      return ip;
    80004128:	bfe1                	j	80004100 <namex+0x6c>
      iunlockput(ip);
    8000412a:	8552                	mv	a0,s4
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	c36080e7          	jalr	-970(ra) # 80003d62 <iunlockput>
      return 0;
    80004134:	8a4e                	mv	s4,s3
    80004136:	b7e9                	j	80004100 <namex+0x6c>
  len = path - s;
    80004138:	40998633          	sub	a2,s3,s1
    8000413c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004140:	09acd863          	bge	s9,s10,800041d0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004144:	4639                	li	a2,14
    80004146:	85a6                	mv	a1,s1
    80004148:	8556                	mv	a0,s5
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	be4080e7          	jalr	-1052(ra) # 80000d2e <memmove>
    80004152:	84ce                	mv	s1,s3
  while(*path == '/')
    80004154:	0004c783          	lbu	a5,0(s1)
    80004158:	01279763          	bne	a5,s2,80004166 <namex+0xd2>
    path++;
    8000415c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000415e:	0004c783          	lbu	a5,0(s1)
    80004162:	ff278de3          	beq	a5,s2,8000415c <namex+0xc8>
    ilock(ip);
    80004166:	8552                	mv	a0,s4
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	998080e7          	jalr	-1640(ra) # 80003b00 <ilock>
    if(ip->type != T_DIR){
    80004170:	044a1783          	lh	a5,68(s4)
    80004174:	f98790e3          	bne	a5,s8,800040f4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004178:	000b0563          	beqz	s6,80004182 <namex+0xee>
    8000417c:	0004c783          	lbu	a5,0(s1)
    80004180:	dfd9                	beqz	a5,8000411e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004182:	865e                	mv	a2,s7
    80004184:	85d6                	mv	a1,s5
    80004186:	8552                	mv	a0,s4
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	e5c080e7          	jalr	-420(ra) # 80003fe4 <dirlookup>
    80004190:	89aa                	mv	s3,a0
    80004192:	dd41                	beqz	a0,8000412a <namex+0x96>
    iunlockput(ip);
    80004194:	8552                	mv	a0,s4
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	bcc080e7          	jalr	-1076(ra) # 80003d62 <iunlockput>
    ip = next;
    8000419e:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041a0:	0004c783          	lbu	a5,0(s1)
    800041a4:	01279763          	bne	a5,s2,800041b2 <namex+0x11e>
    path++;
    800041a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041aa:	0004c783          	lbu	a5,0(s1)
    800041ae:	ff278de3          	beq	a5,s2,800041a8 <namex+0x114>
  if(*path == 0)
    800041b2:	cb9d                	beqz	a5,800041e8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800041b4:	0004c783          	lbu	a5,0(s1)
    800041b8:	89a6                	mv	s3,s1
  len = path - s;
    800041ba:	8d5e                	mv	s10,s7
    800041bc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041be:	01278963          	beq	a5,s2,800041d0 <namex+0x13c>
    800041c2:	dbbd                	beqz	a5,80004138 <namex+0xa4>
    path++;
    800041c4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041c6:	0009c783          	lbu	a5,0(s3)
    800041ca:	ff279ce3          	bne	a5,s2,800041c2 <namex+0x12e>
    800041ce:	b7ad                	j	80004138 <namex+0xa4>
    memmove(name, s, len);
    800041d0:	2601                	sext.w	a2,a2
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8556                	mv	a0,s5
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b58080e7          	jalr	-1192(ra) # 80000d2e <memmove>
    name[len] = 0;
    800041de:	9d56                	add	s10,s10,s5
    800041e0:	000d0023          	sb	zero,0(s10)
    800041e4:	84ce                	mv	s1,s3
    800041e6:	b7bd                	j	80004154 <namex+0xc0>
  if(nameiparent){
    800041e8:	f00b0ce3          	beqz	s6,80004100 <namex+0x6c>
    iput(ip);
    800041ec:	8552                	mv	a0,s4
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	acc080e7          	jalr	-1332(ra) # 80003cba <iput>
    return 0;
    800041f6:	4a01                	li	s4,0
    800041f8:	b721                	j	80004100 <namex+0x6c>

00000000800041fa <dirlink>:
{
    800041fa:	7139                	addi	sp,sp,-64
    800041fc:	fc06                	sd	ra,56(sp)
    800041fe:	f822                	sd	s0,48(sp)
    80004200:	f426                	sd	s1,40(sp)
    80004202:	f04a                	sd	s2,32(sp)
    80004204:	ec4e                	sd	s3,24(sp)
    80004206:	e852                	sd	s4,16(sp)
    80004208:	0080                	addi	s0,sp,64
    8000420a:	892a                	mv	s2,a0
    8000420c:	8a2e                	mv	s4,a1
    8000420e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004210:	4601                	li	a2,0
    80004212:	00000097          	auipc	ra,0x0
    80004216:	dd2080e7          	jalr	-558(ra) # 80003fe4 <dirlookup>
    8000421a:	e93d                	bnez	a0,80004290 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421c:	04c92483          	lw	s1,76(s2)
    80004220:	c49d                	beqz	s1,8000424e <dirlink+0x54>
    80004222:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004224:	4741                	li	a4,16
    80004226:	86a6                	mv	a3,s1
    80004228:	fc040613          	addi	a2,s0,-64
    8000422c:	4581                	li	a1,0
    8000422e:	854a                	mv	a0,s2
    80004230:	00000097          	auipc	ra,0x0
    80004234:	b84080e7          	jalr	-1148(ra) # 80003db4 <readi>
    80004238:	47c1                	li	a5,16
    8000423a:	06f51163          	bne	a0,a5,8000429c <dirlink+0xa2>
    if(de.inum == 0)
    8000423e:	fc045783          	lhu	a5,-64(s0)
    80004242:	c791                	beqz	a5,8000424e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004244:	24c1                	addiw	s1,s1,16
    80004246:	04c92783          	lw	a5,76(s2)
    8000424a:	fcf4ede3          	bltu	s1,a5,80004224 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000424e:	4639                	li	a2,14
    80004250:	85d2                	mv	a1,s4
    80004252:	fc240513          	addi	a0,s0,-62
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	b88080e7          	jalr	-1144(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000425e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004262:	4741                	li	a4,16
    80004264:	86a6                	mv	a3,s1
    80004266:	fc040613          	addi	a2,s0,-64
    8000426a:	4581                	li	a1,0
    8000426c:	854a                	mv	a0,s2
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	c3e080e7          	jalr	-962(ra) # 80003eac <writei>
    80004276:	1541                	addi	a0,a0,-16
    80004278:	00a03533          	snez	a0,a0
    8000427c:	40a00533          	neg	a0,a0
}
    80004280:	70e2                	ld	ra,56(sp)
    80004282:	7442                	ld	s0,48(sp)
    80004284:	74a2                	ld	s1,40(sp)
    80004286:	7902                	ld	s2,32(sp)
    80004288:	69e2                	ld	s3,24(sp)
    8000428a:	6a42                	ld	s4,16(sp)
    8000428c:	6121                	addi	sp,sp,64
    8000428e:	8082                	ret
    iput(ip);
    80004290:	00000097          	auipc	ra,0x0
    80004294:	a2a080e7          	jalr	-1494(ra) # 80003cba <iput>
    return -1;
    80004298:	557d                	li	a0,-1
    8000429a:	b7dd                	j	80004280 <dirlink+0x86>
      panic("dirlink read");
    8000429c:	00004517          	auipc	a0,0x4
    800042a0:	46c50513          	addi	a0,a0,1132 # 80008708 <syscalls+0x1e8>
    800042a4:	ffffc097          	auipc	ra,0xffffc
    800042a8:	29c080e7          	jalr	668(ra) # 80000540 <panic>

00000000800042ac <namei>:

struct inode*
namei(char *path)
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042b4:	fe040613          	addi	a2,s0,-32
    800042b8:	4581                	li	a1,0
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	dda080e7          	jalr	-550(ra) # 80004094 <namex>
}
    800042c2:	60e2                	ld	ra,24(sp)
    800042c4:	6442                	ld	s0,16(sp)
    800042c6:	6105                	addi	sp,sp,32
    800042c8:	8082                	ret

00000000800042ca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042ca:	1141                	addi	sp,sp,-16
    800042cc:	e406                	sd	ra,8(sp)
    800042ce:	e022                	sd	s0,0(sp)
    800042d0:	0800                	addi	s0,sp,16
    800042d2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042d4:	4585                	li	a1,1
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	dbe080e7          	jalr	-578(ra) # 80004094 <namex>
}
    800042de:	60a2                	ld	ra,8(sp)
    800042e0:	6402                	ld	s0,0(sp)
    800042e2:	0141                	addi	sp,sp,16
    800042e4:	8082                	ret

00000000800042e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042f2:	0001d917          	auipc	s2,0x1d
    800042f6:	b6e90913          	addi	s2,s2,-1170 # 80020e60 <log>
    800042fa:	01892583          	lw	a1,24(s2)
    800042fe:	02892503          	lw	a0,40(s2)
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	fe6080e7          	jalr	-26(ra) # 800032e8 <bread>
    8000430a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000430c:	02c92683          	lw	a3,44(s2)
    80004310:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004312:	02d05863          	blez	a3,80004342 <write_head+0x5c>
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	b7a78793          	addi	a5,a5,-1158 # 80020e90 <log+0x30>
    8000431e:	05c50713          	addi	a4,a0,92
    80004322:	36fd                	addiw	a3,a3,-1
    80004324:	02069613          	slli	a2,a3,0x20
    80004328:	01e65693          	srli	a3,a2,0x1e
    8000432c:	0001d617          	auipc	a2,0x1d
    80004330:	b6860613          	addi	a2,a2,-1176 # 80020e94 <log+0x34>
    80004334:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004336:	4390                	lw	a2,0(a5)
    80004338:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000433a:	0791                	addi	a5,a5,4
    8000433c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000433e:	fed79ce3          	bne	a5,a3,80004336 <write_head+0x50>
  }
  bwrite(buf);
    80004342:	8526                	mv	a0,s1
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	096080e7          	jalr	150(ra) # 800033da <bwrite>
  brelse(buf);
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	0ca080e7          	jalr	202(ra) # 80003418 <brelse>
}
    80004356:	60e2                	ld	ra,24(sp)
    80004358:	6442                	ld	s0,16(sp)
    8000435a:	64a2                	ld	s1,8(sp)
    8000435c:	6902                	ld	s2,0(sp)
    8000435e:	6105                	addi	sp,sp,32
    80004360:	8082                	ret

0000000080004362 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004362:	0001d797          	auipc	a5,0x1d
    80004366:	b2a7a783          	lw	a5,-1238(a5) # 80020e8c <log+0x2c>
    8000436a:	0af05d63          	blez	a5,80004424 <install_trans+0xc2>
{
    8000436e:	7139                	addi	sp,sp,-64
    80004370:	fc06                	sd	ra,56(sp)
    80004372:	f822                	sd	s0,48(sp)
    80004374:	f426                	sd	s1,40(sp)
    80004376:	f04a                	sd	s2,32(sp)
    80004378:	ec4e                	sd	s3,24(sp)
    8000437a:	e852                	sd	s4,16(sp)
    8000437c:	e456                	sd	s5,8(sp)
    8000437e:	e05a                	sd	s6,0(sp)
    80004380:	0080                	addi	s0,sp,64
    80004382:	8b2a                	mv	s6,a0
    80004384:	0001da97          	auipc	s5,0x1d
    80004388:	b0ca8a93          	addi	s5,s5,-1268 # 80020e90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438e:	0001d997          	auipc	s3,0x1d
    80004392:	ad298993          	addi	s3,s3,-1326 # 80020e60 <log>
    80004396:	a00d                	j	800043b8 <install_trans+0x56>
    brelse(lbuf);
    80004398:	854a                	mv	a0,s2
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	07e080e7          	jalr	126(ra) # 80003418 <brelse>
    brelse(dbuf);
    800043a2:	8526                	mv	a0,s1
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	074080e7          	jalr	116(ra) # 80003418 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ac:	2a05                	addiw	s4,s4,1
    800043ae:	0a91                	addi	s5,s5,4
    800043b0:	02c9a783          	lw	a5,44(s3)
    800043b4:	04fa5e63          	bge	s4,a5,80004410 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b8:	0189a583          	lw	a1,24(s3)
    800043bc:	014585bb          	addw	a1,a1,s4
    800043c0:	2585                	addiw	a1,a1,1
    800043c2:	0289a503          	lw	a0,40(s3)
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	f22080e7          	jalr	-222(ra) # 800032e8 <bread>
    800043ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043d0:	000aa583          	lw	a1,0(s5)
    800043d4:	0289a503          	lw	a0,40(s3)
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	f10080e7          	jalr	-240(ra) # 800032e8 <bread>
    800043e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043e2:	40000613          	li	a2,1024
    800043e6:	05890593          	addi	a1,s2,88
    800043ea:	05850513          	addi	a0,a0,88
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	940080e7          	jalr	-1728(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043f6:	8526                	mv	a0,s1
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	fe2080e7          	jalr	-30(ra) # 800033da <bwrite>
    if(recovering == 0)
    80004400:	f80b1ce3          	bnez	s6,80004398 <install_trans+0x36>
      bunpin(dbuf);
    80004404:	8526                	mv	a0,s1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	0ec080e7          	jalr	236(ra) # 800034f2 <bunpin>
    8000440e:	b769                	j	80004398 <install_trans+0x36>
}
    80004410:	70e2                	ld	ra,56(sp)
    80004412:	7442                	ld	s0,48(sp)
    80004414:	74a2                	ld	s1,40(sp)
    80004416:	7902                	ld	s2,32(sp)
    80004418:	69e2                	ld	s3,24(sp)
    8000441a:	6a42                	ld	s4,16(sp)
    8000441c:	6aa2                	ld	s5,8(sp)
    8000441e:	6b02                	ld	s6,0(sp)
    80004420:	6121                	addi	sp,sp,64
    80004422:	8082                	ret
    80004424:	8082                	ret

0000000080004426 <initlog>:
{
    80004426:	7179                	addi	sp,sp,-48
    80004428:	f406                	sd	ra,40(sp)
    8000442a:	f022                	sd	s0,32(sp)
    8000442c:	ec26                	sd	s1,24(sp)
    8000442e:	e84a                	sd	s2,16(sp)
    80004430:	e44e                	sd	s3,8(sp)
    80004432:	1800                	addi	s0,sp,48
    80004434:	892a                	mv	s2,a0
    80004436:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004438:	0001d497          	auipc	s1,0x1d
    8000443c:	a2848493          	addi	s1,s1,-1496 # 80020e60 <log>
    80004440:	00004597          	auipc	a1,0x4
    80004444:	2d858593          	addi	a1,a1,728 # 80008718 <syscalls+0x1f8>
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	6fc080e7          	jalr	1788(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004452:	0149a583          	lw	a1,20(s3)
    80004456:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004458:	0109a783          	lw	a5,16(s3)
    8000445c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000445e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004462:	854a                	mv	a0,s2
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	e84080e7          	jalr	-380(ra) # 800032e8 <bread>
  log.lh.n = lh->n;
    8000446c:	4d34                	lw	a3,88(a0)
    8000446e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004470:	02d05663          	blez	a3,8000449c <initlog+0x76>
    80004474:	05c50793          	addi	a5,a0,92
    80004478:	0001d717          	auipc	a4,0x1d
    8000447c:	a1870713          	addi	a4,a4,-1512 # 80020e90 <log+0x30>
    80004480:	36fd                	addiw	a3,a3,-1
    80004482:	02069613          	slli	a2,a3,0x20
    80004486:	01e65693          	srli	a3,a2,0x1e
    8000448a:	06050613          	addi	a2,a0,96
    8000448e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004490:	4390                	lw	a2,0(a5)
    80004492:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004494:	0791                	addi	a5,a5,4
    80004496:	0711                	addi	a4,a4,4
    80004498:	fed79ce3          	bne	a5,a3,80004490 <initlog+0x6a>
  brelse(buf);
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	f7c080e7          	jalr	-132(ra) # 80003418 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044a4:	4505                	li	a0,1
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	ebc080e7          	jalr	-324(ra) # 80004362 <install_trans>
  log.lh.n = 0;
    800044ae:	0001d797          	auipc	a5,0x1d
    800044b2:	9c07af23          	sw	zero,-1570(a5) # 80020e8c <log+0x2c>
  write_head(); // clear the log
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	e30080e7          	jalr	-464(ra) # 800042e6 <write_head>
}
    800044be:	70a2                	ld	ra,40(sp)
    800044c0:	7402                	ld	s0,32(sp)
    800044c2:	64e2                	ld	s1,24(sp)
    800044c4:	6942                	ld	s2,16(sp)
    800044c6:	69a2                	ld	s3,8(sp)
    800044c8:	6145                	addi	sp,sp,48
    800044ca:	8082                	ret

00000000800044cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044cc:	1101                	addi	sp,sp,-32
    800044ce:	ec06                	sd	ra,24(sp)
    800044d0:	e822                	sd	s0,16(sp)
    800044d2:	e426                	sd	s1,8(sp)
    800044d4:	e04a                	sd	s2,0(sp)
    800044d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044d8:	0001d517          	auipc	a0,0x1d
    800044dc:	98850513          	addi	a0,a0,-1656 # 80020e60 <log>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800044e8:	0001d497          	auipc	s1,0x1d
    800044ec:	97848493          	addi	s1,s1,-1672 # 80020e60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044f0:	4979                	li	s2,30
    800044f2:	a039                	j	80004500 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044f4:	85a6                	mv	a1,s1
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	e3a080e7          	jalr	-454(ra) # 80002332 <sleep>
    if(log.committing){
    80004500:	50dc                	lw	a5,36(s1)
    80004502:	fbed                	bnez	a5,800044f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004504:	5098                	lw	a4,32(s1)
    80004506:	2705                	addiw	a4,a4,1
    80004508:	0007069b          	sext.w	a3,a4
    8000450c:	0027179b          	slliw	a5,a4,0x2
    80004510:	9fb9                	addw	a5,a5,a4
    80004512:	0017979b          	slliw	a5,a5,0x1
    80004516:	54d8                	lw	a4,44(s1)
    80004518:	9fb9                	addw	a5,a5,a4
    8000451a:	00f95963          	bge	s2,a5,8000452c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000451e:	85a6                	mv	a1,s1
    80004520:	8526                	mv	a0,s1
    80004522:	ffffe097          	auipc	ra,0xffffe
    80004526:	e10080e7          	jalr	-496(ra) # 80002332 <sleep>
    8000452a:	bfd9                	j	80004500 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	93450513          	addi	a0,a0,-1740 # 80020e60 <log>
    80004534:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	754080e7          	jalr	1876(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6902                	ld	s2,0(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000454a:	7139                	addi	sp,sp,-64
    8000454c:	fc06                	sd	ra,56(sp)
    8000454e:	f822                	sd	s0,48(sp)
    80004550:	f426                	sd	s1,40(sp)
    80004552:	f04a                	sd	s2,32(sp)
    80004554:	ec4e                	sd	s3,24(sp)
    80004556:	e852                	sd	s4,16(sp)
    80004558:	e456                	sd	s5,8(sp)
    8000455a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000455c:	0001d497          	auipc	s1,0x1d
    80004560:	90448493          	addi	s1,s1,-1788 # 80020e60 <log>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	670080e7          	jalr	1648(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000456e:	509c                	lw	a5,32(s1)
    80004570:	37fd                	addiw	a5,a5,-1
    80004572:	0007891b          	sext.w	s2,a5
    80004576:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004578:	50dc                	lw	a5,36(s1)
    8000457a:	e7b9                	bnez	a5,800045c8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000457c:	04091e63          	bnez	s2,800045d8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004580:	0001d497          	auipc	s1,0x1d
    80004584:	8e048493          	addi	s1,s1,-1824 # 80020e60 <log>
    80004588:	4785                	li	a5,1
    8000458a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000458c:	8526                	mv	a0,s1
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6fc080e7          	jalr	1788(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004596:	54dc                	lw	a5,44(s1)
    80004598:	06f04763          	bgtz	a5,80004606 <end_op+0xbc>
    acquire(&log.lock);
    8000459c:	0001d497          	auipc	s1,0x1d
    800045a0:	8c448493          	addi	s1,s1,-1852 # 80020e60 <log>
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	630080e7          	jalr	1584(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800045ae:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045b2:	8526                	mv	a0,s1
    800045b4:	ffffe097          	auipc	ra,0xffffe
    800045b8:	de2080e7          	jalr	-542(ra) # 80002396 <wakeup>
    release(&log.lock);
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6cc080e7          	jalr	1740(ra) # 80000c8a <release>
}
    800045c6:	a03d                	j	800045f4 <end_op+0xaa>
    panic("log.committing");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	15850513          	addi	a0,a0,344 # 80008720 <syscalls+0x200>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f70080e7          	jalr	-144(ra) # 80000540 <panic>
    wakeup(&log);
    800045d8:	0001d497          	auipc	s1,0x1d
    800045dc:	88848493          	addi	s1,s1,-1912 # 80020e60 <log>
    800045e0:	8526                	mv	a0,s1
    800045e2:	ffffe097          	auipc	ra,0xffffe
    800045e6:	db4080e7          	jalr	-588(ra) # 80002396 <wakeup>
  release(&log.lock);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	69e080e7          	jalr	1694(ra) # 80000c8a <release>
}
    800045f4:	70e2                	ld	ra,56(sp)
    800045f6:	7442                	ld	s0,48(sp)
    800045f8:	74a2                	ld	s1,40(sp)
    800045fa:	7902                	ld	s2,32(sp)
    800045fc:	69e2                	ld	s3,24(sp)
    800045fe:	6a42                	ld	s4,16(sp)
    80004600:	6aa2                	ld	s5,8(sp)
    80004602:	6121                	addi	sp,sp,64
    80004604:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004606:	0001da97          	auipc	s5,0x1d
    8000460a:	88aa8a93          	addi	s5,s5,-1910 # 80020e90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000460e:	0001da17          	auipc	s4,0x1d
    80004612:	852a0a13          	addi	s4,s4,-1966 # 80020e60 <log>
    80004616:	018a2583          	lw	a1,24(s4)
    8000461a:	012585bb          	addw	a1,a1,s2
    8000461e:	2585                	addiw	a1,a1,1
    80004620:	028a2503          	lw	a0,40(s4)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	cc4080e7          	jalr	-828(ra) # 800032e8 <bread>
    8000462c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000462e:	000aa583          	lw	a1,0(s5)
    80004632:	028a2503          	lw	a0,40(s4)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	cb2080e7          	jalr	-846(ra) # 800032e8 <bread>
    8000463e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004640:	40000613          	li	a2,1024
    80004644:	05850593          	addi	a1,a0,88
    80004648:	05848513          	addi	a0,s1,88
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	6e2080e7          	jalr	1762(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004654:	8526                	mv	a0,s1
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	d84080e7          	jalr	-636(ra) # 800033da <bwrite>
    brelse(from);
    8000465e:	854e                	mv	a0,s3
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	db8080e7          	jalr	-584(ra) # 80003418 <brelse>
    brelse(to);
    80004668:	8526                	mv	a0,s1
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	dae080e7          	jalr	-594(ra) # 80003418 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004672:	2905                	addiw	s2,s2,1
    80004674:	0a91                	addi	s5,s5,4
    80004676:	02ca2783          	lw	a5,44(s4)
    8000467a:	f8f94ee3          	blt	s2,a5,80004616 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	c68080e7          	jalr	-920(ra) # 800042e6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004686:	4501                	li	a0,0
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	cda080e7          	jalr	-806(ra) # 80004362 <install_trans>
    log.lh.n = 0;
    80004690:	0001c797          	auipc	a5,0x1c
    80004694:	7e07ae23          	sw	zero,2044(a5) # 80020e8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	c4e080e7          	jalr	-946(ra) # 800042e6 <write_head>
    800046a0:	bdf5                	j	8000459c <end_op+0x52>

00000000800046a2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046a2:	1101                	addi	sp,sp,-32
    800046a4:	ec06                	sd	ra,24(sp)
    800046a6:	e822                	sd	s0,16(sp)
    800046a8:	e426                	sd	s1,8(sp)
    800046aa:	e04a                	sd	s2,0(sp)
    800046ac:	1000                	addi	s0,sp,32
    800046ae:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046b0:	0001c917          	auipc	s2,0x1c
    800046b4:	7b090913          	addi	s2,s2,1968 # 80020e60 <log>
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	51c080e7          	jalr	1308(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046c2:	02c92603          	lw	a2,44(s2)
    800046c6:	47f5                	li	a5,29
    800046c8:	06c7c563          	blt	a5,a2,80004732 <log_write+0x90>
    800046cc:	0001c797          	auipc	a5,0x1c
    800046d0:	7b07a783          	lw	a5,1968(a5) # 80020e7c <log+0x1c>
    800046d4:	37fd                	addiw	a5,a5,-1
    800046d6:	04f65e63          	bge	a2,a5,80004732 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046da:	0001c797          	auipc	a5,0x1c
    800046de:	7a67a783          	lw	a5,1958(a5) # 80020e80 <log+0x20>
    800046e2:	06f05063          	blez	a5,80004742 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046e6:	4781                	li	a5,0
    800046e8:	06c05563          	blez	a2,80004752 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ec:	44cc                	lw	a1,12(s1)
    800046ee:	0001c717          	auipc	a4,0x1c
    800046f2:	7a270713          	addi	a4,a4,1954 # 80020e90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046f6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f8:	4314                	lw	a3,0(a4)
    800046fa:	04b68c63          	beq	a3,a1,80004752 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046fe:	2785                	addiw	a5,a5,1
    80004700:	0711                	addi	a4,a4,4
    80004702:	fef61be3          	bne	a2,a5,800046f8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004706:	0621                	addi	a2,a2,8
    80004708:	060a                	slli	a2,a2,0x2
    8000470a:	0001c797          	auipc	a5,0x1c
    8000470e:	75678793          	addi	a5,a5,1878 # 80020e60 <log>
    80004712:	97b2                	add	a5,a5,a2
    80004714:	44d8                	lw	a4,12(s1)
    80004716:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004718:	8526                	mv	a0,s1
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	d9c080e7          	jalr	-612(ra) # 800034b6 <bpin>
    log.lh.n++;
    80004722:	0001c717          	auipc	a4,0x1c
    80004726:	73e70713          	addi	a4,a4,1854 # 80020e60 <log>
    8000472a:	575c                	lw	a5,44(a4)
    8000472c:	2785                	addiw	a5,a5,1
    8000472e:	d75c                	sw	a5,44(a4)
    80004730:	a82d                	j	8000476a <log_write+0xc8>
    panic("too big a transaction");
    80004732:	00004517          	auipc	a0,0x4
    80004736:	ffe50513          	addi	a0,a0,-2 # 80008730 <syscalls+0x210>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004742:	00004517          	auipc	a0,0x4
    80004746:	00650513          	addi	a0,a0,6 # 80008748 <syscalls+0x228>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004752:	00878693          	addi	a3,a5,8
    80004756:	068a                	slli	a3,a3,0x2
    80004758:	0001c717          	auipc	a4,0x1c
    8000475c:	70870713          	addi	a4,a4,1800 # 80020e60 <log>
    80004760:	9736                	add	a4,a4,a3
    80004762:	44d4                	lw	a3,12(s1)
    80004764:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004766:	faf609e3          	beq	a2,a5,80004718 <log_write+0x76>
  }
  release(&log.lock);
    8000476a:	0001c517          	auipc	a0,0x1c
    8000476e:	6f650513          	addi	a0,a0,1782 # 80020e60 <log>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	518080e7          	jalr	1304(ra) # 80000c8a <release>
}
    8000477a:	60e2                	ld	ra,24(sp)
    8000477c:	6442                	ld	s0,16(sp)
    8000477e:	64a2                	ld	s1,8(sp)
    80004780:	6902                	ld	s2,0(sp)
    80004782:	6105                	addi	sp,sp,32
    80004784:	8082                	ret

0000000080004786 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004786:	1101                	addi	sp,sp,-32
    80004788:	ec06                	sd	ra,24(sp)
    8000478a:	e822                	sd	s0,16(sp)
    8000478c:	e426                	sd	s1,8(sp)
    8000478e:	e04a                	sd	s2,0(sp)
    80004790:	1000                	addi	s0,sp,32
    80004792:	84aa                	mv	s1,a0
    80004794:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004796:	00004597          	auipc	a1,0x4
    8000479a:	fd258593          	addi	a1,a1,-46 # 80008768 <syscalls+0x248>
    8000479e:	0521                	addi	a0,a0,8
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	3a6080e7          	jalr	934(ra) # 80000b46 <initlock>
  lk->name = name;
    800047a8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047b0:	0204a423          	sw	zero,40(s1)
}
    800047b4:	60e2                	ld	ra,24(sp)
    800047b6:	6442                	ld	s0,16(sp)
    800047b8:	64a2                	ld	s1,8(sp)
    800047ba:	6902                	ld	s2,0(sp)
    800047bc:	6105                	addi	sp,sp,32
    800047be:	8082                	ret

00000000800047c0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047c0:	1101                	addi	sp,sp,-32
    800047c2:	ec06                	sd	ra,24(sp)
    800047c4:	e822                	sd	s0,16(sp)
    800047c6:	e426                	sd	s1,8(sp)
    800047c8:	e04a                	sd	s2,0(sp)
    800047ca:	1000                	addi	s0,sp,32
    800047cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ce:	00850913          	addi	s2,a0,8
    800047d2:	854a                	mv	a0,s2
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800047dc:	409c                	lw	a5,0(s1)
    800047de:	cb89                	beqz	a5,800047f0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047e0:	85ca                	mv	a1,s2
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffe097          	auipc	ra,0xffffe
    800047e8:	b4e080e7          	jalr	-1202(ra) # 80002332 <sleep>
  while (lk->locked) {
    800047ec:	409c                	lw	a5,0(s1)
    800047ee:	fbed                	bnez	a5,800047e0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047f0:	4785                	li	a5,1
    800047f2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047f4:	ffffd097          	auipc	ra,0xffffd
    800047f8:	390080e7          	jalr	912(ra) # 80001b84 <myproc>
    800047fc:	5d1c                	lw	a5,56(a0)
    800047fe:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004800:	854a                	mv	a0,s2
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	488080e7          	jalr	1160(ra) # 80000c8a <release>
}
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6902                	ld	s2,0(sp)
    80004812:	6105                	addi	sp,sp,32
    80004814:	8082                	ret

0000000080004816 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004816:	1101                	addi	sp,sp,-32
    80004818:	ec06                	sd	ra,24(sp)
    8000481a:	e822                	sd	s0,16(sp)
    8000481c:	e426                	sd	s1,8(sp)
    8000481e:	e04a                	sd	s2,0(sp)
    80004820:	1000                	addi	s0,sp,32
    80004822:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004824:	00850913          	addi	s2,a0,8
    80004828:	854a                	mv	a0,s2
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	3ac080e7          	jalr	940(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004832:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004836:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffe097          	auipc	ra,0xffffe
    80004840:	b5a080e7          	jalr	-1190(ra) # 80002396 <wakeup>
  release(&lk->lk);
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	444080e7          	jalr	1092(ra) # 80000c8a <release>
}
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6902                	ld	s2,0(sp)
    80004856:	6105                	addi	sp,sp,32
    80004858:	8082                	ret

000000008000485a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000485a:	7179                	addi	sp,sp,-48
    8000485c:	f406                	sd	ra,40(sp)
    8000485e:	f022                	sd	s0,32(sp)
    80004860:	ec26                	sd	s1,24(sp)
    80004862:	e84a                	sd	s2,16(sp)
    80004864:	e44e                	sd	s3,8(sp)
    80004866:	1800                	addi	s0,sp,48
    80004868:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000486a:	00850913          	addi	s2,a0,8
    8000486e:	854a                	mv	a0,s2
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	366080e7          	jalr	870(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004878:	409c                	lw	a5,0(s1)
    8000487a:	ef99                	bnez	a5,80004898 <holdingsleep+0x3e>
    8000487c:	4481                	li	s1,0
  release(&lk->lk);
    8000487e:	854a                	mv	a0,s2
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	40a080e7          	jalr	1034(ra) # 80000c8a <release>
  return r;
}
    80004888:	8526                	mv	a0,s1
    8000488a:	70a2                	ld	ra,40(sp)
    8000488c:	7402                	ld	s0,32(sp)
    8000488e:	64e2                	ld	s1,24(sp)
    80004890:	6942                	ld	s2,16(sp)
    80004892:	69a2                	ld	s3,8(sp)
    80004894:	6145                	addi	sp,sp,48
    80004896:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004898:	0284a983          	lw	s3,40(s1)
    8000489c:	ffffd097          	auipc	ra,0xffffd
    800048a0:	2e8080e7          	jalr	744(ra) # 80001b84 <myproc>
    800048a4:	5d04                	lw	s1,56(a0)
    800048a6:	413484b3          	sub	s1,s1,s3
    800048aa:	0014b493          	seqz	s1,s1
    800048ae:	bfc1                	j	8000487e <holdingsleep+0x24>

00000000800048b0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048b0:	1141                	addi	sp,sp,-16
    800048b2:	e406                	sd	ra,8(sp)
    800048b4:	e022                	sd	s0,0(sp)
    800048b6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048b8:	00004597          	auipc	a1,0x4
    800048bc:	ec058593          	addi	a1,a1,-320 # 80008778 <syscalls+0x258>
    800048c0:	0001c517          	auipc	a0,0x1c
    800048c4:	6e850513          	addi	a0,a0,1768 # 80020fa8 <ftable>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	27e080e7          	jalr	638(ra) # 80000b46 <initlock>
}
    800048d0:	60a2                	ld	ra,8(sp)
    800048d2:	6402                	ld	s0,0(sp)
    800048d4:	0141                	addi	sp,sp,16
    800048d6:	8082                	ret

00000000800048d8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048d8:	1101                	addi	sp,sp,-32
    800048da:	ec06                	sd	ra,24(sp)
    800048dc:	e822                	sd	s0,16(sp)
    800048de:	e426                	sd	s1,8(sp)
    800048e0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048e2:	0001c517          	auipc	a0,0x1c
    800048e6:	6c650513          	addi	a0,a0,1734 # 80020fa8 <ftable>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	2ec080e7          	jalr	748(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048f2:	0001c497          	auipc	s1,0x1c
    800048f6:	6ce48493          	addi	s1,s1,1742 # 80020fc0 <ftable+0x18>
    800048fa:	0001d717          	auipc	a4,0x1d
    800048fe:	66670713          	addi	a4,a4,1638 # 80021f60 <disk>
    if(f->ref == 0){
    80004902:	40dc                	lw	a5,4(s1)
    80004904:	cf99                	beqz	a5,80004922 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004906:	02848493          	addi	s1,s1,40
    8000490a:	fee49ce3          	bne	s1,a4,80004902 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000490e:	0001c517          	auipc	a0,0x1c
    80004912:	69a50513          	addi	a0,a0,1690 # 80020fa8 <ftable>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	374080e7          	jalr	884(ra) # 80000c8a <release>
  return 0;
    8000491e:	4481                	li	s1,0
    80004920:	a819                	j	80004936 <filealloc+0x5e>
      f->ref = 1;
    80004922:	4785                	li	a5,1
    80004924:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004926:	0001c517          	auipc	a0,0x1c
    8000492a:	68250513          	addi	a0,a0,1666 # 80020fa8 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	35c080e7          	jalr	860(ra) # 80000c8a <release>
}
    80004936:	8526                	mv	a0,s1
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret

0000000080004942 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	1000                	addi	s0,sp,32
    8000494c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000494e:	0001c517          	auipc	a0,0x1c
    80004952:	65a50513          	addi	a0,a0,1626 # 80020fa8 <ftable>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	280080e7          	jalr	640(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000495e:	40dc                	lw	a5,4(s1)
    80004960:	02f05263          	blez	a5,80004984 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004964:	2785                	addiw	a5,a5,1
    80004966:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004968:	0001c517          	auipc	a0,0x1c
    8000496c:	64050513          	addi	a0,a0,1600 # 80020fa8 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	31a080e7          	jalr	794(ra) # 80000c8a <release>
  return f;
}
    80004978:	8526                	mv	a0,s1
    8000497a:	60e2                	ld	ra,24(sp)
    8000497c:	6442                	ld	s0,16(sp)
    8000497e:	64a2                	ld	s1,8(sp)
    80004980:	6105                	addi	sp,sp,32
    80004982:	8082                	ret
    panic("filedup");
    80004984:	00004517          	auipc	a0,0x4
    80004988:	dfc50513          	addi	a0,a0,-516 # 80008780 <syscalls+0x260>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	bb4080e7          	jalr	-1100(ra) # 80000540 <panic>

0000000080004994 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004994:	7139                	addi	sp,sp,-64
    80004996:	fc06                	sd	ra,56(sp)
    80004998:	f822                	sd	s0,48(sp)
    8000499a:	f426                	sd	s1,40(sp)
    8000499c:	f04a                	sd	s2,32(sp)
    8000499e:	ec4e                	sd	s3,24(sp)
    800049a0:	e852                	sd	s4,16(sp)
    800049a2:	e456                	sd	s5,8(sp)
    800049a4:	0080                	addi	s0,sp,64
    800049a6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049a8:	0001c517          	auipc	a0,0x1c
    800049ac:	60050513          	addi	a0,a0,1536 # 80020fa8 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	226080e7          	jalr	550(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049b8:	40dc                	lw	a5,4(s1)
    800049ba:	06f05163          	blez	a5,80004a1c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049be:	37fd                	addiw	a5,a5,-1
    800049c0:	0007871b          	sext.w	a4,a5
    800049c4:	c0dc                	sw	a5,4(s1)
    800049c6:	06e04363          	bgtz	a4,80004a2c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049ca:	0004a903          	lw	s2,0(s1)
    800049ce:	0094ca83          	lbu	s5,9(s1)
    800049d2:	0104ba03          	ld	s4,16(s1)
    800049d6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049da:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049de:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049e2:	0001c517          	auipc	a0,0x1c
    800049e6:	5c650513          	addi	a0,a0,1478 # 80020fa8 <ftable>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	2a0080e7          	jalr	672(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049f2:	4785                	li	a5,1
    800049f4:	04f90d63          	beq	s2,a5,80004a4e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049f8:	3979                	addiw	s2,s2,-2
    800049fa:	4785                	li	a5,1
    800049fc:	0527e063          	bltu	a5,s2,80004a3c <fileclose+0xa8>
    begin_op();
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	acc080e7          	jalr	-1332(ra) # 800044cc <begin_op>
    iput(ff.ip);
    80004a08:	854e                	mv	a0,s3
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	2b0080e7          	jalr	688(ra) # 80003cba <iput>
    end_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	b38080e7          	jalr	-1224(ra) # 8000454a <end_op>
    80004a1a:	a00d                	j	80004a3c <fileclose+0xa8>
    panic("fileclose");
    80004a1c:	00004517          	auipc	a0,0x4
    80004a20:	d6c50513          	addi	a0,a0,-660 # 80008788 <syscalls+0x268>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	b1c080e7          	jalr	-1252(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a2c:	0001c517          	auipc	a0,0x1c
    80004a30:	57c50513          	addi	a0,a0,1404 # 80020fa8 <ftable>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	256080e7          	jalr	598(ra) # 80000c8a <release>
  }
}
    80004a3c:	70e2                	ld	ra,56(sp)
    80004a3e:	7442                	ld	s0,48(sp)
    80004a40:	74a2                	ld	s1,40(sp)
    80004a42:	7902                	ld	s2,32(sp)
    80004a44:	69e2                	ld	s3,24(sp)
    80004a46:	6a42                	ld	s4,16(sp)
    80004a48:	6aa2                	ld	s5,8(sp)
    80004a4a:	6121                	addi	sp,sp,64
    80004a4c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a4e:	85d6                	mv	a1,s5
    80004a50:	8552                	mv	a0,s4
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	34c080e7          	jalr	844(ra) # 80004d9e <pipeclose>
    80004a5a:	b7cd                	j	80004a3c <fileclose+0xa8>

0000000080004a5c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a5c:	715d                	addi	sp,sp,-80
    80004a5e:	e486                	sd	ra,72(sp)
    80004a60:	e0a2                	sd	s0,64(sp)
    80004a62:	fc26                	sd	s1,56(sp)
    80004a64:	f84a                	sd	s2,48(sp)
    80004a66:	f44e                	sd	s3,40(sp)
    80004a68:	0880                	addi	s0,sp,80
    80004a6a:	84aa                	mv	s1,a0
    80004a6c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	116080e7          	jalr	278(ra) # 80001b84 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a76:	409c                	lw	a5,0(s1)
    80004a78:	37f9                	addiw	a5,a5,-2
    80004a7a:	4705                	li	a4,1
    80004a7c:	04f76763          	bltu	a4,a5,80004aca <filestat+0x6e>
    80004a80:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a82:	6c88                	ld	a0,24(s1)
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	07c080e7          	jalr	124(ra) # 80003b00 <ilock>
    stati(f->ip, &st);
    80004a8c:	fb840593          	addi	a1,s0,-72
    80004a90:	6c88                	ld	a0,24(s1)
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	2f8080e7          	jalr	760(ra) # 80003d8a <stati>
    iunlock(f->ip);
    80004a9a:	6c88                	ld	a0,24(s1)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	126080e7          	jalr	294(ra) # 80003bc2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aa4:	46e1                	li	a3,24
    80004aa6:	fb840613          	addi	a2,s0,-72
    80004aaa:	85ce                	mv	a1,s3
    80004aac:	05893503          	ld	a0,88(s2)
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	bbc080e7          	jalr	-1092(ra) # 8000166c <copyout>
    80004ab8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004abc:	60a6                	ld	ra,72(sp)
    80004abe:	6406                	ld	s0,64(sp)
    80004ac0:	74e2                	ld	s1,56(sp)
    80004ac2:	7942                	ld	s2,48(sp)
    80004ac4:	79a2                	ld	s3,40(sp)
    80004ac6:	6161                	addi	sp,sp,80
    80004ac8:	8082                	ret
  return -1;
    80004aca:	557d                	li	a0,-1
    80004acc:	bfc5                	j	80004abc <filestat+0x60>

0000000080004ace <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ace:	7179                	addi	sp,sp,-48
    80004ad0:	f406                	sd	ra,40(sp)
    80004ad2:	f022                	sd	s0,32(sp)
    80004ad4:	ec26                	sd	s1,24(sp)
    80004ad6:	e84a                	sd	s2,16(sp)
    80004ad8:	e44e                	sd	s3,8(sp)
    80004ada:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004adc:	00854783          	lbu	a5,8(a0)
    80004ae0:	c3d5                	beqz	a5,80004b84 <fileread+0xb6>
    80004ae2:	84aa                	mv	s1,a0
    80004ae4:	89ae                	mv	s3,a1
    80004ae6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae8:	411c                	lw	a5,0(a0)
    80004aea:	4705                	li	a4,1
    80004aec:	04e78963          	beq	a5,a4,80004b3e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004af0:	470d                	li	a4,3
    80004af2:	04e78d63          	beq	a5,a4,80004b4c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af6:	4709                	li	a4,2
    80004af8:	06e79e63          	bne	a5,a4,80004b74 <fileread+0xa6>
    ilock(f->ip);
    80004afc:	6d08                	ld	a0,24(a0)
    80004afe:	fffff097          	auipc	ra,0xfffff
    80004b02:	002080e7          	jalr	2(ra) # 80003b00 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b06:	874a                	mv	a4,s2
    80004b08:	5094                	lw	a3,32(s1)
    80004b0a:	864e                	mv	a2,s3
    80004b0c:	4585                	li	a1,1
    80004b0e:	6c88                	ld	a0,24(s1)
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	2a4080e7          	jalr	676(ra) # 80003db4 <readi>
    80004b18:	892a                	mv	s2,a0
    80004b1a:	00a05563          	blez	a0,80004b24 <fileread+0x56>
      f->off += r;
    80004b1e:	509c                	lw	a5,32(s1)
    80004b20:	9fa9                	addw	a5,a5,a0
    80004b22:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	09c080e7          	jalr	156(ra) # 80003bc2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b2e:	854a                	mv	a0,s2
    80004b30:	70a2                	ld	ra,40(sp)
    80004b32:	7402                	ld	s0,32(sp)
    80004b34:	64e2                	ld	s1,24(sp)
    80004b36:	6942                	ld	s2,16(sp)
    80004b38:	69a2                	ld	s3,8(sp)
    80004b3a:	6145                	addi	sp,sp,48
    80004b3c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b3e:	6908                	ld	a0,16(a0)
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	3c6080e7          	jalr	966(ra) # 80004f06 <piperead>
    80004b48:	892a                	mv	s2,a0
    80004b4a:	b7d5                	j	80004b2e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b4c:	02451783          	lh	a5,36(a0)
    80004b50:	03079693          	slli	a3,a5,0x30
    80004b54:	92c1                	srli	a3,a3,0x30
    80004b56:	4725                	li	a4,9
    80004b58:	02d76863          	bltu	a4,a3,80004b88 <fileread+0xba>
    80004b5c:	0792                	slli	a5,a5,0x4
    80004b5e:	0001c717          	auipc	a4,0x1c
    80004b62:	3aa70713          	addi	a4,a4,938 # 80020f08 <devsw>
    80004b66:	97ba                	add	a5,a5,a4
    80004b68:	639c                	ld	a5,0(a5)
    80004b6a:	c38d                	beqz	a5,80004b8c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b6c:	4505                	li	a0,1
    80004b6e:	9782                	jalr	a5
    80004b70:	892a                	mv	s2,a0
    80004b72:	bf75                	j	80004b2e <fileread+0x60>
    panic("fileread");
    80004b74:	00004517          	auipc	a0,0x4
    80004b78:	c2450513          	addi	a0,a0,-988 # 80008798 <syscalls+0x278>
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	9c4080e7          	jalr	-1596(ra) # 80000540 <panic>
    return -1;
    80004b84:	597d                	li	s2,-1
    80004b86:	b765                	j	80004b2e <fileread+0x60>
      return -1;
    80004b88:	597d                	li	s2,-1
    80004b8a:	b755                	j	80004b2e <fileread+0x60>
    80004b8c:	597d                	li	s2,-1
    80004b8e:	b745                	j	80004b2e <fileread+0x60>

0000000080004b90 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b90:	715d                	addi	sp,sp,-80
    80004b92:	e486                	sd	ra,72(sp)
    80004b94:	e0a2                	sd	s0,64(sp)
    80004b96:	fc26                	sd	s1,56(sp)
    80004b98:	f84a                	sd	s2,48(sp)
    80004b9a:	f44e                	sd	s3,40(sp)
    80004b9c:	f052                	sd	s4,32(sp)
    80004b9e:	ec56                	sd	s5,24(sp)
    80004ba0:	e85a                	sd	s6,16(sp)
    80004ba2:	e45e                	sd	s7,8(sp)
    80004ba4:	e062                	sd	s8,0(sp)
    80004ba6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ba8:	00954783          	lbu	a5,9(a0)
    80004bac:	10078663          	beqz	a5,80004cb8 <filewrite+0x128>
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	8b2e                	mv	s6,a1
    80004bb4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bb6:	411c                	lw	a5,0(a0)
    80004bb8:	4705                	li	a4,1
    80004bba:	02e78263          	beq	a5,a4,80004bde <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bbe:	470d                	li	a4,3
    80004bc0:	02e78663          	beq	a5,a4,80004bec <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc4:	4709                	li	a4,2
    80004bc6:	0ee79163          	bne	a5,a4,80004ca8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bca:	0ac05d63          	blez	a2,80004c84 <filewrite+0xf4>
    int i = 0;
    80004bce:	4981                	li	s3,0
    80004bd0:	6b85                	lui	s7,0x1
    80004bd2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bd6:	6c05                	lui	s8,0x1
    80004bd8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bdc:	a861                	j	80004c74 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bde:	6908                	ld	a0,16(a0)
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	22e080e7          	jalr	558(ra) # 80004e0e <pipewrite>
    80004be8:	8a2a                	mv	s4,a0
    80004bea:	a045                	j	80004c8a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bec:	02451783          	lh	a5,36(a0)
    80004bf0:	03079693          	slli	a3,a5,0x30
    80004bf4:	92c1                	srli	a3,a3,0x30
    80004bf6:	4725                	li	a4,9
    80004bf8:	0cd76263          	bltu	a4,a3,80004cbc <filewrite+0x12c>
    80004bfc:	0792                	slli	a5,a5,0x4
    80004bfe:	0001c717          	auipc	a4,0x1c
    80004c02:	30a70713          	addi	a4,a4,778 # 80020f08 <devsw>
    80004c06:	97ba                	add	a5,a5,a4
    80004c08:	679c                	ld	a5,8(a5)
    80004c0a:	cbdd                	beqz	a5,80004cc0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c0c:	4505                	li	a0,1
    80004c0e:	9782                	jalr	a5
    80004c10:	8a2a                	mv	s4,a0
    80004c12:	a8a5                	j	80004c8a <filewrite+0xfa>
    80004c14:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	8b4080e7          	jalr	-1868(ra) # 800044cc <begin_op>
      ilock(f->ip);
    80004c20:	01893503          	ld	a0,24(s2)
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	edc080e7          	jalr	-292(ra) # 80003b00 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c2c:	8756                	mv	a4,s5
    80004c2e:	02092683          	lw	a3,32(s2)
    80004c32:	01698633          	add	a2,s3,s6
    80004c36:	4585                	li	a1,1
    80004c38:	01893503          	ld	a0,24(s2)
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	270080e7          	jalr	624(ra) # 80003eac <writei>
    80004c44:	84aa                	mv	s1,a0
    80004c46:	00a05763          	blez	a0,80004c54 <filewrite+0xc4>
        f->off += r;
    80004c4a:	02092783          	lw	a5,32(s2)
    80004c4e:	9fa9                	addw	a5,a5,a0
    80004c50:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c54:	01893503          	ld	a0,24(s2)
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	f6a080e7          	jalr	-150(ra) # 80003bc2 <iunlock>
      end_op();
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	8ea080e7          	jalr	-1814(ra) # 8000454a <end_op>

      if(r != n1){
    80004c68:	009a9f63          	bne	s5,s1,80004c86 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c6c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c70:	0149db63          	bge	s3,s4,80004c86 <filewrite+0xf6>
      int n1 = n - i;
    80004c74:	413a04bb          	subw	s1,s4,s3
    80004c78:	0004879b          	sext.w	a5,s1
    80004c7c:	f8fbdce3          	bge	s7,a5,80004c14 <filewrite+0x84>
    80004c80:	84e2                	mv	s1,s8
    80004c82:	bf49                	j	80004c14 <filewrite+0x84>
    int i = 0;
    80004c84:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c86:	013a1f63          	bne	s4,s3,80004ca4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c8a:	8552                	mv	a0,s4
    80004c8c:	60a6                	ld	ra,72(sp)
    80004c8e:	6406                	ld	s0,64(sp)
    80004c90:	74e2                	ld	s1,56(sp)
    80004c92:	7942                	ld	s2,48(sp)
    80004c94:	79a2                	ld	s3,40(sp)
    80004c96:	7a02                	ld	s4,32(sp)
    80004c98:	6ae2                	ld	s5,24(sp)
    80004c9a:	6b42                	ld	s6,16(sp)
    80004c9c:	6ba2                	ld	s7,8(sp)
    80004c9e:	6c02                	ld	s8,0(sp)
    80004ca0:	6161                	addi	sp,sp,80
    80004ca2:	8082                	ret
    ret = (i == n ? n : -1);
    80004ca4:	5a7d                	li	s4,-1
    80004ca6:	b7d5                	j	80004c8a <filewrite+0xfa>
    panic("filewrite");
    80004ca8:	00004517          	auipc	a0,0x4
    80004cac:	b0050513          	addi	a0,a0,-1280 # 800087a8 <syscalls+0x288>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	890080e7          	jalr	-1904(ra) # 80000540 <panic>
    return -1;
    80004cb8:	5a7d                	li	s4,-1
    80004cba:	bfc1                	j	80004c8a <filewrite+0xfa>
      return -1;
    80004cbc:	5a7d                	li	s4,-1
    80004cbe:	b7f1                	j	80004c8a <filewrite+0xfa>
    80004cc0:	5a7d                	li	s4,-1
    80004cc2:	b7e1                	j	80004c8a <filewrite+0xfa>

0000000080004cc4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cc4:	7179                	addi	sp,sp,-48
    80004cc6:	f406                	sd	ra,40(sp)
    80004cc8:	f022                	sd	s0,32(sp)
    80004cca:	ec26                	sd	s1,24(sp)
    80004ccc:	e84a                	sd	s2,16(sp)
    80004cce:	e44e                	sd	s3,8(sp)
    80004cd0:	e052                	sd	s4,0(sp)
    80004cd2:	1800                	addi	s0,sp,48
    80004cd4:	84aa                	mv	s1,a0
    80004cd6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cd8:	0005b023          	sd	zero,0(a1)
    80004cdc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	bf8080e7          	jalr	-1032(ra) # 800048d8 <filealloc>
    80004ce8:	e088                	sd	a0,0(s1)
    80004cea:	c551                	beqz	a0,80004d76 <pipealloc+0xb2>
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	bec080e7          	jalr	-1044(ra) # 800048d8 <filealloc>
    80004cf4:	00aa3023          	sd	a0,0(s4)
    80004cf8:	c92d                	beqz	a0,80004d6a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	dec080e7          	jalr	-532(ra) # 80000ae6 <kalloc>
    80004d02:	892a                	mv	s2,a0
    80004d04:	c125                	beqz	a0,80004d64 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d06:	4985                	li	s3,1
    80004d08:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d0c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d10:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d14:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d18:	00004597          	auipc	a1,0x4
    80004d1c:	aa058593          	addi	a1,a1,-1376 # 800087b8 <syscalls+0x298>
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	e26080e7          	jalr	-474(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004d28:	609c                	ld	a5,0(s1)
    80004d2a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d2e:	609c                	ld	a5,0(s1)
    80004d30:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d34:	609c                	ld	a5,0(s1)
    80004d36:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d3a:	609c                	ld	a5,0(s1)
    80004d3c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d40:	000a3783          	ld	a5,0(s4)
    80004d44:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d48:	000a3783          	ld	a5,0(s4)
    80004d4c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d50:	000a3783          	ld	a5,0(s4)
    80004d54:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d58:	000a3783          	ld	a5,0(s4)
    80004d5c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d60:	4501                	li	a0,0
    80004d62:	a025                	j	80004d8a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d64:	6088                	ld	a0,0(s1)
    80004d66:	e501                	bnez	a0,80004d6e <pipealloc+0xaa>
    80004d68:	a039                	j	80004d76 <pipealloc+0xb2>
    80004d6a:	6088                	ld	a0,0(s1)
    80004d6c:	c51d                	beqz	a0,80004d9a <pipealloc+0xd6>
    fileclose(*f0);
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	c26080e7          	jalr	-986(ra) # 80004994 <fileclose>
  if(*f1)
    80004d76:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d7a:	557d                	li	a0,-1
  if(*f1)
    80004d7c:	c799                	beqz	a5,80004d8a <pipealloc+0xc6>
    fileclose(*f1);
    80004d7e:	853e                	mv	a0,a5
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	c14080e7          	jalr	-1004(ra) # 80004994 <fileclose>
  return -1;
    80004d88:	557d                	li	a0,-1
}
    80004d8a:	70a2                	ld	ra,40(sp)
    80004d8c:	7402                	ld	s0,32(sp)
    80004d8e:	64e2                	ld	s1,24(sp)
    80004d90:	6942                	ld	s2,16(sp)
    80004d92:	69a2                	ld	s3,8(sp)
    80004d94:	6a02                	ld	s4,0(sp)
    80004d96:	6145                	addi	sp,sp,48
    80004d98:	8082                	ret
  return -1;
    80004d9a:	557d                	li	a0,-1
    80004d9c:	b7fd                	j	80004d8a <pipealloc+0xc6>

0000000080004d9e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d9e:	1101                	addi	sp,sp,-32
    80004da0:	ec06                	sd	ra,24(sp)
    80004da2:	e822                	sd	s0,16(sp)
    80004da4:	e426                	sd	s1,8(sp)
    80004da6:	e04a                	sd	s2,0(sp)
    80004da8:	1000                	addi	s0,sp,32
    80004daa:	84aa                	mv	s1,a0
    80004dac:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	e28080e7          	jalr	-472(ra) # 80000bd6 <acquire>
  if(writable){
    80004db6:	02090d63          	beqz	s2,80004df0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dba:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dbe:	21848513          	addi	a0,s1,536
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	5d4080e7          	jalr	1492(ra) # 80002396 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dca:	2204b783          	ld	a5,544(s1)
    80004dce:	eb95                	bnez	a5,80004e02 <pipeclose+0x64>
    release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	eb8080e7          	jalr	-328(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	c0c080e7          	jalr	-1012(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004de4:	60e2                	ld	ra,24(sp)
    80004de6:	6442                	ld	s0,16(sp)
    80004de8:	64a2                	ld	s1,8(sp)
    80004dea:	6902                	ld	s2,0(sp)
    80004dec:	6105                	addi	sp,sp,32
    80004dee:	8082                	ret
    pi->readopen = 0;
    80004df0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004df4:	21c48513          	addi	a0,s1,540
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	59e080e7          	jalr	1438(ra) # 80002396 <wakeup>
    80004e00:	b7e9                	j	80004dca <pipeclose+0x2c>
    release(&pi->lock);
    80004e02:	8526                	mv	a0,s1
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	e86080e7          	jalr	-378(ra) # 80000c8a <release>
}
    80004e0c:	bfe1                	j	80004de4 <pipeclose+0x46>

0000000080004e0e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e0e:	711d                	addi	sp,sp,-96
    80004e10:	ec86                	sd	ra,88(sp)
    80004e12:	e8a2                	sd	s0,80(sp)
    80004e14:	e4a6                	sd	s1,72(sp)
    80004e16:	e0ca                	sd	s2,64(sp)
    80004e18:	fc4e                	sd	s3,56(sp)
    80004e1a:	f852                	sd	s4,48(sp)
    80004e1c:	f456                	sd	s5,40(sp)
    80004e1e:	f05a                	sd	s6,32(sp)
    80004e20:	ec5e                	sd	s7,24(sp)
    80004e22:	e862                	sd	s8,16(sp)
    80004e24:	1080                	addi	s0,sp,96
    80004e26:	84aa                	mv	s1,a0
    80004e28:	8aae                	mv	s5,a1
    80004e2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	d58080e7          	jalr	-680(ra) # 80001b84 <myproc>
    80004e34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	d9e080e7          	jalr	-610(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e40:	0b405663          	blez	s4,80004eec <pipewrite+0xde>
  int i = 0;
    80004e44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e48:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e4c:	21c48b93          	addi	s7,s1,540
    80004e50:	a089                	j	80004e92 <pipewrite+0x84>
      release(&pi->lock);
    80004e52:	8526                	mv	a0,s1
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	e36080e7          	jalr	-458(ra) # 80000c8a <release>
      return -1;
    80004e5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e5e:	854a                	mv	a0,s2
    80004e60:	60e6                	ld	ra,88(sp)
    80004e62:	6446                	ld	s0,80(sp)
    80004e64:	64a6                	ld	s1,72(sp)
    80004e66:	6906                	ld	s2,64(sp)
    80004e68:	79e2                	ld	s3,56(sp)
    80004e6a:	7a42                	ld	s4,48(sp)
    80004e6c:	7aa2                	ld	s5,40(sp)
    80004e6e:	7b02                	ld	s6,32(sp)
    80004e70:	6be2                	ld	s7,24(sp)
    80004e72:	6c42                	ld	s8,16(sp)
    80004e74:	6125                	addi	sp,sp,96
    80004e76:	8082                	ret
      wakeup(&pi->nread);
    80004e78:	8562                	mv	a0,s8
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	51c080e7          	jalr	1308(ra) # 80002396 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e82:	85a6                	mv	a1,s1
    80004e84:	855e                	mv	a0,s7
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	4ac080e7          	jalr	1196(ra) # 80002332 <sleep>
  while(i < n){
    80004e8e:	07495063          	bge	s2,s4,80004eee <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e92:	2204a783          	lw	a5,544(s1)
    80004e96:	dfd5                	beqz	a5,80004e52 <pipewrite+0x44>
    80004e98:	854e                	mv	a0,s3
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	740080e7          	jalr	1856(ra) # 800025da <killed>
    80004ea2:	f945                	bnez	a0,80004e52 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ea4:	2184a783          	lw	a5,536(s1)
    80004ea8:	21c4a703          	lw	a4,540(s1)
    80004eac:	2007879b          	addiw	a5,a5,512
    80004eb0:	fcf704e3          	beq	a4,a5,80004e78 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eb4:	4685                	li	a3,1
    80004eb6:	01590633          	add	a2,s2,s5
    80004eba:	faf40593          	addi	a1,s0,-81
    80004ebe:	0589b503          	ld	a0,88(s3)
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	836080e7          	jalr	-1994(ra) # 800016f8 <copyin>
    80004eca:	03650263          	beq	a0,s6,80004eee <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ece:	21c4a783          	lw	a5,540(s1)
    80004ed2:	0017871b          	addiw	a4,a5,1
    80004ed6:	20e4ae23          	sw	a4,540(s1)
    80004eda:	1ff7f793          	andi	a5,a5,511
    80004ede:	97a6                	add	a5,a5,s1
    80004ee0:	faf44703          	lbu	a4,-81(s0)
    80004ee4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ee8:	2905                	addiw	s2,s2,1
    80004eea:	b755                	j	80004e8e <pipewrite+0x80>
  int i = 0;
    80004eec:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004eee:	21848513          	addi	a0,s1,536
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	4a4080e7          	jalr	1188(ra) # 80002396 <wakeup>
  release(&pi->lock);
    80004efa:	8526                	mv	a0,s1
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	d8e080e7          	jalr	-626(ra) # 80000c8a <release>
  return i;
    80004f04:	bfa9                	j	80004e5e <pipewrite+0x50>

0000000080004f06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f06:	715d                	addi	sp,sp,-80
    80004f08:	e486                	sd	ra,72(sp)
    80004f0a:	e0a2                	sd	s0,64(sp)
    80004f0c:	fc26                	sd	s1,56(sp)
    80004f0e:	f84a                	sd	s2,48(sp)
    80004f10:	f44e                	sd	s3,40(sp)
    80004f12:	f052                	sd	s4,32(sp)
    80004f14:	ec56                	sd	s5,24(sp)
    80004f16:	e85a                	sd	s6,16(sp)
    80004f18:	0880                	addi	s0,sp,80
    80004f1a:	84aa                	mv	s1,a0
    80004f1c:	892e                	mv	s2,a1
    80004f1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	c64080e7          	jalr	-924(ra) # 80001b84 <myproc>
    80004f28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f2a:	8526                	mv	a0,s1
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f34:	2184a703          	lw	a4,536(s1)
    80004f38:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f40:	02f71763          	bne	a4,a5,80004f6e <piperead+0x68>
    80004f44:	2244a783          	lw	a5,548(s1)
    80004f48:	c39d                	beqz	a5,80004f6e <piperead+0x68>
    if(killed(pr)){
    80004f4a:	8552                	mv	a0,s4
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	68e080e7          	jalr	1678(ra) # 800025da <killed>
    80004f54:	e949                	bnez	a0,80004fe6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f56:	85a6                	mv	a1,s1
    80004f58:	854e                	mv	a0,s3
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	3d8080e7          	jalr	984(ra) # 80002332 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f62:	2184a703          	lw	a4,536(s1)
    80004f66:	21c4a783          	lw	a5,540(s1)
    80004f6a:	fcf70de3          	beq	a4,a5,80004f44 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f70:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f72:	05505463          	blez	s5,80004fba <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f76:	2184a783          	lw	a5,536(s1)
    80004f7a:	21c4a703          	lw	a4,540(s1)
    80004f7e:	02f70e63          	beq	a4,a5,80004fba <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f82:	0017871b          	addiw	a4,a5,1
    80004f86:	20e4ac23          	sw	a4,536(s1)
    80004f8a:	1ff7f793          	andi	a5,a5,511
    80004f8e:	97a6                	add	a5,a5,s1
    80004f90:	0187c783          	lbu	a5,24(a5)
    80004f94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f98:	4685                	li	a3,1
    80004f9a:	fbf40613          	addi	a2,s0,-65
    80004f9e:	85ca                	mv	a1,s2
    80004fa0:	058a3503          	ld	a0,88(s4)
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	6c8080e7          	jalr	1736(ra) # 8000166c <copyout>
    80004fac:	01650763          	beq	a0,s6,80004fba <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb0:	2985                	addiw	s3,s3,1
    80004fb2:	0905                	addi	s2,s2,1
    80004fb4:	fd3a91e3          	bne	s5,s3,80004f76 <piperead+0x70>
    80004fb8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fba:	21c48513          	addi	a0,s1,540
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	3d8080e7          	jalr	984(ra) # 80002396 <wakeup>
  release(&pi->lock);
    80004fc6:	8526                	mv	a0,s1
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
  return i;
}
    80004fd0:	854e                	mv	a0,s3
    80004fd2:	60a6                	ld	ra,72(sp)
    80004fd4:	6406                	ld	s0,64(sp)
    80004fd6:	74e2                	ld	s1,56(sp)
    80004fd8:	7942                	ld	s2,48(sp)
    80004fda:	79a2                	ld	s3,40(sp)
    80004fdc:	7a02                	ld	s4,32(sp)
    80004fde:	6ae2                	ld	s5,24(sp)
    80004fe0:	6b42                	ld	s6,16(sp)
    80004fe2:	6161                	addi	sp,sp,80
    80004fe4:	8082                	ret
      release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	ca2080e7          	jalr	-862(ra) # 80000c8a <release>
      return -1;
    80004ff0:	59fd                	li	s3,-1
    80004ff2:	bff9                	j	80004fd0 <piperead+0xca>

0000000080004ff4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ff4:	1141                	addi	sp,sp,-16
    80004ff6:	e422                	sd	s0,8(sp)
    80004ff8:	0800                	addi	s0,sp,16
    80004ffa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ffc:	8905                	andi	a0,a0,1
    80004ffe:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005000:	8b89                	andi	a5,a5,2
    80005002:	c399                	beqz	a5,80005008 <flags2perm+0x14>
      perm |= PTE_W;
    80005004:	00456513          	ori	a0,a0,4
    return perm;
}
    80005008:	6422                	ld	s0,8(sp)
    8000500a:	0141                	addi	sp,sp,16
    8000500c:	8082                	ret

000000008000500e <exec>:

int
exec(char *path, char **argv)
{
    8000500e:	de010113          	addi	sp,sp,-544
    80005012:	20113c23          	sd	ra,536(sp)
    80005016:	20813823          	sd	s0,528(sp)
    8000501a:	20913423          	sd	s1,520(sp)
    8000501e:	21213023          	sd	s2,512(sp)
    80005022:	ffce                	sd	s3,504(sp)
    80005024:	fbd2                	sd	s4,496(sp)
    80005026:	f7d6                	sd	s5,488(sp)
    80005028:	f3da                	sd	s6,480(sp)
    8000502a:	efde                	sd	s7,472(sp)
    8000502c:	ebe2                	sd	s8,464(sp)
    8000502e:	e7e6                	sd	s9,456(sp)
    80005030:	e3ea                	sd	s10,448(sp)
    80005032:	ff6e                	sd	s11,440(sp)
    80005034:	1400                	addi	s0,sp,544
    80005036:	892a                	mv	s2,a0
    80005038:	dea43423          	sd	a0,-536(s0)
    8000503c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	b44080e7          	jalr	-1212(ra) # 80001b84 <myproc>
    80005048:	84aa                	mv	s1,a0

  begin_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	482080e7          	jalr	1154(ra) # 800044cc <begin_op>

  if((ip = namei(path)) == 0){
    80005052:	854a                	mv	a0,s2
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	258080e7          	jalr	600(ra) # 800042ac <namei>
    8000505c:	c93d                	beqz	a0,800050d2 <exec+0xc4>
    8000505e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	aa0080e7          	jalr	-1376(ra) # 80003b00 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005068:	04000713          	li	a4,64
    8000506c:	4681                	li	a3,0
    8000506e:	e5040613          	addi	a2,s0,-432
    80005072:	4581                	li	a1,0
    80005074:	8556                	mv	a0,s5
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	d3e080e7          	jalr	-706(ra) # 80003db4 <readi>
    8000507e:	04000793          	li	a5,64
    80005082:	00f51a63          	bne	a0,a5,80005096 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005086:	e5042703          	lw	a4,-432(s0)
    8000508a:	464c47b7          	lui	a5,0x464c4
    8000508e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005092:	04f70663          	beq	a4,a5,800050de <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005096:	8556                	mv	a0,s5
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	cca080e7          	jalr	-822(ra) # 80003d62 <iunlockput>
    end_op();
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	4aa080e7          	jalr	1194(ra) # 8000454a <end_op>
  }
  return -1;
    800050a8:	557d                	li	a0,-1
}
    800050aa:	21813083          	ld	ra,536(sp)
    800050ae:	21013403          	ld	s0,528(sp)
    800050b2:	20813483          	ld	s1,520(sp)
    800050b6:	20013903          	ld	s2,512(sp)
    800050ba:	79fe                	ld	s3,504(sp)
    800050bc:	7a5e                	ld	s4,496(sp)
    800050be:	7abe                	ld	s5,488(sp)
    800050c0:	7b1e                	ld	s6,480(sp)
    800050c2:	6bfe                	ld	s7,472(sp)
    800050c4:	6c5e                	ld	s8,464(sp)
    800050c6:	6cbe                	ld	s9,456(sp)
    800050c8:	6d1e                	ld	s10,448(sp)
    800050ca:	7dfa                	ld	s11,440(sp)
    800050cc:	22010113          	addi	sp,sp,544
    800050d0:	8082                	ret
    end_op();
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	478080e7          	jalr	1144(ra) # 8000454a <end_op>
    return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	b7f9                	j	800050aa <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	b68080e7          	jalr	-1176(ra) # 80001c48 <proc_pagetable>
    800050e8:	8b2a                	mv	s6,a0
    800050ea:	d555                	beqz	a0,80005096 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ec:	e7042783          	lw	a5,-400(s0)
    800050f0:	e8845703          	lhu	a4,-376(s0)
    800050f4:	c735                	beqz	a4,80005160 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050fc:	6a05                	lui	s4,0x1
    800050fe:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005102:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005106:	6d85                	lui	s11,0x1
    80005108:	7d7d                	lui	s10,0xfffff
    8000510a:	ac3d                	j	80005348 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000510c:	00003517          	auipc	a0,0x3
    80005110:	6b450513          	addi	a0,a0,1716 # 800087c0 <syscalls+0x2a0>
    80005114:	ffffb097          	auipc	ra,0xffffb
    80005118:	42c080e7          	jalr	1068(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000511c:	874a                	mv	a4,s2
    8000511e:	009c86bb          	addw	a3,s9,s1
    80005122:	4581                	li	a1,0
    80005124:	8556                	mv	a0,s5
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	c8e080e7          	jalr	-882(ra) # 80003db4 <readi>
    8000512e:	2501                	sext.w	a0,a0
    80005130:	1aa91963          	bne	s2,a0,800052e2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005134:	009d84bb          	addw	s1,s11,s1
    80005138:	013d09bb          	addw	s3,s10,s3
    8000513c:	1f74f663          	bgeu	s1,s7,80005328 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005140:	02049593          	slli	a1,s1,0x20
    80005144:	9181                	srli	a1,a1,0x20
    80005146:	95e2                	add	a1,a1,s8
    80005148:	855a                	mv	a0,s6
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	f12080e7          	jalr	-238(ra) # 8000105c <walkaddr>
    80005152:	862a                	mv	a2,a0
    if(pa == 0)
    80005154:	dd45                	beqz	a0,8000510c <exec+0xfe>
      n = PGSIZE;
    80005156:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005158:	fd49f2e3          	bgeu	s3,s4,8000511c <exec+0x10e>
      n = sz - i;
    8000515c:	894e                	mv	s2,s3
    8000515e:	bf7d                	j	8000511c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005160:	4901                	li	s2,0
  iunlockput(ip);
    80005162:	8556                	mv	a0,s5
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	bfe080e7          	jalr	-1026(ra) # 80003d62 <iunlockput>
  end_op();
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	3de080e7          	jalr	990(ra) # 8000454a <end_op>
  p = myproc();
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	a10080e7          	jalr	-1520(ra) # 80001b84 <myproc>
    8000517c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000517e:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005182:	6785                	lui	a5,0x1
    80005184:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005186:	97ca                	add	a5,a5,s2
    80005188:	777d                	lui	a4,0xfffff
    8000518a:	8ff9                	and	a5,a5,a4
    8000518c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005190:	4691                	li	a3,4
    80005192:	6609                	lui	a2,0x2
    80005194:	963e                	add	a2,a2,a5
    80005196:	85be                	mv	a1,a5
    80005198:	855a                	mv	a0,s6
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	276080e7          	jalr	630(ra) # 80001410 <uvmalloc>
    800051a2:	8c2a                	mv	s8,a0
  ip = 0;
    800051a4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051a6:	12050e63          	beqz	a0,800052e2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051aa:	75f9                	lui	a1,0xffffe
    800051ac:	95aa                	add	a1,a1,a0
    800051ae:	855a                	mv	a0,s6
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	48a080e7          	jalr	1162(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800051b8:	7afd                	lui	s5,0xfffff
    800051ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051bc:	df043783          	ld	a5,-528(s0)
    800051c0:	6388                	ld	a0,0(a5)
    800051c2:	c925                	beqz	a0,80005232 <exec+0x224>
    800051c4:	e9040993          	addi	s3,s0,-368
    800051c8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	c7e080e7          	jalr	-898(ra) # 80000e4e <strlen>
    800051d8:	0015079b          	addiw	a5,a0,1
    800051dc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051e0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051e4:	13596663          	bltu	s2,s5,80005310 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051e8:	df043d83          	ld	s11,-528(s0)
    800051ec:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051f0:	8552                	mv	a0,s4
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	c5c080e7          	jalr	-932(ra) # 80000e4e <strlen>
    800051fa:	0015069b          	addiw	a3,a0,1
    800051fe:	8652                	mv	a2,s4
    80005200:	85ca                	mv	a1,s2
    80005202:	855a                	mv	a0,s6
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	468080e7          	jalr	1128(ra) # 8000166c <copyout>
    8000520c:	10054663          	bltz	a0,80005318 <exec+0x30a>
    ustack[argc] = sp;
    80005210:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005214:	0485                	addi	s1,s1,1
    80005216:	008d8793          	addi	a5,s11,8
    8000521a:	def43823          	sd	a5,-528(s0)
    8000521e:	008db503          	ld	a0,8(s11)
    80005222:	c911                	beqz	a0,80005236 <exec+0x228>
    if(argc >= MAXARG)
    80005224:	09a1                	addi	s3,s3,8
    80005226:	fb3c95e3          	bne	s9,s3,800051d0 <exec+0x1c2>
  sz = sz1;
    8000522a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000522e:	4a81                	li	s5,0
    80005230:	a84d                	j	800052e2 <exec+0x2d4>
  sp = sz;
    80005232:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005234:	4481                	li	s1,0
  ustack[argc] = 0;
    80005236:	00349793          	slli	a5,s1,0x3
    8000523a:	f9078793          	addi	a5,a5,-112
    8000523e:	97a2                	add	a5,a5,s0
    80005240:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005244:	00148693          	addi	a3,s1,1
    80005248:	068e                	slli	a3,a3,0x3
    8000524a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000524e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005252:	01597663          	bgeu	s2,s5,8000525e <exec+0x250>
  sz = sz1;
    80005256:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000525a:	4a81                	li	s5,0
    8000525c:	a059                	j	800052e2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000525e:	e9040613          	addi	a2,s0,-368
    80005262:	85ca                	mv	a1,s2
    80005264:	855a                	mv	a0,s6
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	406080e7          	jalr	1030(ra) # 8000166c <copyout>
    8000526e:	0a054963          	bltz	a0,80005320 <exec+0x312>
  p->trapframe->a1 = sp;
    80005272:	060bb783          	ld	a5,96(s7)
    80005276:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000527a:	de843783          	ld	a5,-536(s0)
    8000527e:	0007c703          	lbu	a4,0(a5)
    80005282:	cf11                	beqz	a4,8000529e <exec+0x290>
    80005284:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005286:	02f00693          	li	a3,47
    8000528a:	a039                	j	80005298 <exec+0x28a>
      last = s+1;
    8000528c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005290:	0785                	addi	a5,a5,1
    80005292:	fff7c703          	lbu	a4,-1(a5)
    80005296:	c701                	beqz	a4,8000529e <exec+0x290>
    if(*s == '/')
    80005298:	fed71ce3          	bne	a4,a3,80005290 <exec+0x282>
    8000529c:	bfc5                	j	8000528c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000529e:	4641                	li	a2,16
    800052a0:	de843583          	ld	a1,-536(s0)
    800052a4:	160b8513          	addi	a0,s7,352
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	b74080e7          	jalr	-1164(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800052b0:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800052b4:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800052b8:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052bc:	060bb783          	ld	a5,96(s7)
    800052c0:	e6843703          	ld	a4,-408(s0)
    800052c4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052c6:	060bb783          	ld	a5,96(s7)
    800052ca:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ce:	85ea                	mv	a1,s10
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	a14080e7          	jalr	-1516(ra) # 80001ce4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052d8:	0004851b          	sext.w	a0,s1
    800052dc:	b3f9                	j	800050aa <exec+0x9c>
    800052de:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052e2:	df843583          	ld	a1,-520(s0)
    800052e6:	855a                	mv	a0,s6
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	9fc080e7          	jalr	-1540(ra) # 80001ce4 <proc_freepagetable>
  if(ip){
    800052f0:	da0a93e3          	bnez	s5,80005096 <exec+0x88>
  return -1;
    800052f4:	557d                	li	a0,-1
    800052f6:	bb55                	j	800050aa <exec+0x9c>
    800052f8:	df243c23          	sd	s2,-520(s0)
    800052fc:	b7dd                	j	800052e2 <exec+0x2d4>
    800052fe:	df243c23          	sd	s2,-520(s0)
    80005302:	b7c5                	j	800052e2 <exec+0x2d4>
    80005304:	df243c23          	sd	s2,-520(s0)
    80005308:	bfe9                	j	800052e2 <exec+0x2d4>
    8000530a:	df243c23          	sd	s2,-520(s0)
    8000530e:	bfd1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005310:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005314:	4a81                	li	s5,0
    80005316:	b7f1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005318:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000531c:	4a81                	li	s5,0
    8000531e:	b7d1                	j	800052e2 <exec+0x2d4>
  sz = sz1;
    80005320:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005324:	4a81                	li	s5,0
    80005326:	bf75                	j	800052e2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005328:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000532c:	e0843783          	ld	a5,-504(s0)
    80005330:	0017869b          	addiw	a3,a5,1
    80005334:	e0d43423          	sd	a3,-504(s0)
    80005338:	e0043783          	ld	a5,-512(s0)
    8000533c:	0387879b          	addiw	a5,a5,56
    80005340:	e8845703          	lhu	a4,-376(s0)
    80005344:	e0e6dfe3          	bge	a3,a4,80005162 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005348:	2781                	sext.w	a5,a5
    8000534a:	e0f43023          	sd	a5,-512(s0)
    8000534e:	03800713          	li	a4,56
    80005352:	86be                	mv	a3,a5
    80005354:	e1840613          	addi	a2,s0,-488
    80005358:	4581                	li	a1,0
    8000535a:	8556                	mv	a0,s5
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	a58080e7          	jalr	-1448(ra) # 80003db4 <readi>
    80005364:	03800793          	li	a5,56
    80005368:	f6f51be3          	bne	a0,a5,800052de <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000536c:	e1842783          	lw	a5,-488(s0)
    80005370:	4705                	li	a4,1
    80005372:	fae79de3          	bne	a5,a4,8000532c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005376:	e4043483          	ld	s1,-448(s0)
    8000537a:	e3843783          	ld	a5,-456(s0)
    8000537e:	f6f4ede3          	bltu	s1,a5,800052f8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005382:	e2843783          	ld	a5,-472(s0)
    80005386:	94be                	add	s1,s1,a5
    80005388:	f6f4ebe3          	bltu	s1,a5,800052fe <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000538c:	de043703          	ld	a4,-544(s0)
    80005390:	8ff9                	and	a5,a5,a4
    80005392:	fbad                	bnez	a5,80005304 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005394:	e1c42503          	lw	a0,-484(s0)
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	c5c080e7          	jalr	-932(ra) # 80004ff4 <flags2perm>
    800053a0:	86aa                	mv	a3,a0
    800053a2:	8626                	mv	a2,s1
    800053a4:	85ca                	mv	a1,s2
    800053a6:	855a                	mv	a0,s6
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	068080e7          	jalr	104(ra) # 80001410 <uvmalloc>
    800053b0:	dea43c23          	sd	a0,-520(s0)
    800053b4:	d939                	beqz	a0,8000530a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053b6:	e2843c03          	ld	s8,-472(s0)
    800053ba:	e2042c83          	lw	s9,-480(s0)
    800053be:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053c2:	f60b83e3          	beqz	s7,80005328 <exec+0x31a>
    800053c6:	89de                	mv	s3,s7
    800053c8:	4481                	li	s1,0
    800053ca:	bb9d                	j	80005140 <exec+0x132>

00000000800053cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053cc:	7179                	addi	sp,sp,-48
    800053ce:	f406                	sd	ra,40(sp)
    800053d0:	f022                	sd	s0,32(sp)
    800053d2:	ec26                	sd	s1,24(sp)
    800053d4:	e84a                	sd	s2,16(sp)
    800053d6:	1800                	addi	s0,sp,48
    800053d8:	892e                	mv	s2,a1
    800053da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053dc:	fdc40593          	addi	a1,s0,-36
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	b0a080e7          	jalr	-1270(ra) # 80002eea <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053e8:	fdc42703          	lw	a4,-36(s0)
    800053ec:	47bd                	li	a5,15
    800053ee:	02e7eb63          	bltu	a5,a4,80005424 <argfd+0x58>
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	792080e7          	jalr	1938(ra) # 80001b84 <myproc>
    800053fa:	fdc42703          	lw	a4,-36(s0)
    800053fe:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdcf7a>
    80005402:	078e                	slli	a5,a5,0x3
    80005404:	953e                	add	a0,a0,a5
    80005406:	651c                	ld	a5,8(a0)
    80005408:	c385                	beqz	a5,80005428 <argfd+0x5c>
    return -1;
  if(pfd)
    8000540a:	00090463          	beqz	s2,80005412 <argfd+0x46>
    *pfd = fd;
    8000540e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005412:	4501                	li	a0,0
  if(pf)
    80005414:	c091                	beqz	s1,80005418 <argfd+0x4c>
    *pf = f;
    80005416:	e09c                	sd	a5,0(s1)
}
    80005418:	70a2                	ld	ra,40(sp)
    8000541a:	7402                	ld	s0,32(sp)
    8000541c:	64e2                	ld	s1,24(sp)
    8000541e:	6942                	ld	s2,16(sp)
    80005420:	6145                	addi	sp,sp,48
    80005422:	8082                	ret
    return -1;
    80005424:	557d                	li	a0,-1
    80005426:	bfcd                	j	80005418 <argfd+0x4c>
    80005428:	557d                	li	a0,-1
    8000542a:	b7fd                	j	80005418 <argfd+0x4c>

000000008000542c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000542c:	1101                	addi	sp,sp,-32
    8000542e:	ec06                	sd	ra,24(sp)
    80005430:	e822                	sd	s0,16(sp)
    80005432:	e426                	sd	s1,8(sp)
    80005434:	1000                	addi	s0,sp,32
    80005436:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	74c080e7          	jalr	1868(ra) # 80001b84 <myproc>
    80005440:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005442:	0d850793          	addi	a5,a0,216
    80005446:	4501                	li	a0,0
    80005448:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000544a:	6398                	ld	a4,0(a5)
    8000544c:	cb19                	beqz	a4,80005462 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000544e:	2505                	addiw	a0,a0,1
    80005450:	07a1                	addi	a5,a5,8
    80005452:	fed51ce3          	bne	a0,a3,8000544a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005456:	557d                	li	a0,-1
}
    80005458:	60e2                	ld	ra,24(sp)
    8000545a:	6442                	ld	s0,16(sp)
    8000545c:	64a2                	ld	s1,8(sp)
    8000545e:	6105                	addi	sp,sp,32
    80005460:	8082                	ret
      p->ofile[fd] = f;
    80005462:	01a50793          	addi	a5,a0,26
    80005466:	078e                	slli	a5,a5,0x3
    80005468:	963e                	add	a2,a2,a5
    8000546a:	e604                	sd	s1,8(a2)
      return fd;
    8000546c:	b7f5                	j	80005458 <fdalloc+0x2c>

000000008000546e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000546e:	715d                	addi	sp,sp,-80
    80005470:	e486                	sd	ra,72(sp)
    80005472:	e0a2                	sd	s0,64(sp)
    80005474:	fc26                	sd	s1,56(sp)
    80005476:	f84a                	sd	s2,48(sp)
    80005478:	f44e                	sd	s3,40(sp)
    8000547a:	f052                	sd	s4,32(sp)
    8000547c:	ec56                	sd	s5,24(sp)
    8000547e:	e85a                	sd	s6,16(sp)
    80005480:	0880                	addi	s0,sp,80
    80005482:	8b2e                	mv	s6,a1
    80005484:	89b2                	mv	s3,a2
    80005486:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005488:	fb040593          	addi	a1,s0,-80
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	e3e080e7          	jalr	-450(ra) # 800042ca <nameiparent>
    80005494:	84aa                	mv	s1,a0
    80005496:	14050f63          	beqz	a0,800055f4 <create+0x186>
    return 0;

  ilock(dp);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	666080e7          	jalr	1638(ra) # 80003b00 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054a2:	4601                	li	a2,0
    800054a4:	fb040593          	addi	a1,s0,-80
    800054a8:	8526                	mv	a0,s1
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	b3a080e7          	jalr	-1222(ra) # 80003fe4 <dirlookup>
    800054b2:	8aaa                	mv	s5,a0
    800054b4:	c931                	beqz	a0,80005508 <create+0x9a>
    iunlockput(dp);
    800054b6:	8526                	mv	a0,s1
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	8aa080e7          	jalr	-1878(ra) # 80003d62 <iunlockput>
    ilock(ip);
    800054c0:	8556                	mv	a0,s5
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	63e080e7          	jalr	1598(ra) # 80003b00 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054ca:	000b059b          	sext.w	a1,s6
    800054ce:	4789                	li	a5,2
    800054d0:	02f59563          	bne	a1,a5,800054fa <create+0x8c>
    800054d4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcfa4>
    800054d8:	37f9                	addiw	a5,a5,-2
    800054da:	17c2                	slli	a5,a5,0x30
    800054dc:	93c1                	srli	a5,a5,0x30
    800054de:	4705                	li	a4,1
    800054e0:	00f76d63          	bltu	a4,a5,800054fa <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054e4:	8556                	mv	a0,s5
    800054e6:	60a6                	ld	ra,72(sp)
    800054e8:	6406                	ld	s0,64(sp)
    800054ea:	74e2                	ld	s1,56(sp)
    800054ec:	7942                	ld	s2,48(sp)
    800054ee:	79a2                	ld	s3,40(sp)
    800054f0:	7a02                	ld	s4,32(sp)
    800054f2:	6ae2                	ld	s5,24(sp)
    800054f4:	6b42                	ld	s6,16(sp)
    800054f6:	6161                	addi	sp,sp,80
    800054f8:	8082                	ret
    iunlockput(ip);
    800054fa:	8556                	mv	a0,s5
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	866080e7          	jalr	-1946(ra) # 80003d62 <iunlockput>
    return 0;
    80005504:	4a81                	li	s5,0
    80005506:	bff9                	j	800054e4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005508:	85da                	mv	a1,s6
    8000550a:	4088                	lw	a0,0(s1)
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	456080e7          	jalr	1110(ra) # 80003962 <ialloc>
    80005514:	8a2a                	mv	s4,a0
    80005516:	c539                	beqz	a0,80005564 <create+0xf6>
  ilock(ip);
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	5e8080e7          	jalr	1512(ra) # 80003b00 <ilock>
  ip->major = major;
    80005520:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005524:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005528:	4905                	li	s2,1
    8000552a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000552e:	8552                	mv	a0,s4
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	504080e7          	jalr	1284(ra) # 80003a34 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005538:	000b059b          	sext.w	a1,s6
    8000553c:	03258b63          	beq	a1,s2,80005572 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005540:	004a2603          	lw	a2,4(s4)
    80005544:	fb040593          	addi	a1,s0,-80
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	cb0080e7          	jalr	-848(ra) # 800041fa <dirlink>
    80005552:	06054f63          	bltz	a0,800055d0 <create+0x162>
  iunlockput(dp);
    80005556:	8526                	mv	a0,s1
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	80a080e7          	jalr	-2038(ra) # 80003d62 <iunlockput>
  return ip;
    80005560:	8ad2                	mv	s5,s4
    80005562:	b749                	j	800054e4 <create+0x76>
    iunlockput(dp);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	7fc080e7          	jalr	2044(ra) # 80003d62 <iunlockput>
    return 0;
    8000556e:	8ad2                	mv	s5,s4
    80005570:	bf95                	j	800054e4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005572:	004a2603          	lw	a2,4(s4)
    80005576:	00003597          	auipc	a1,0x3
    8000557a:	26a58593          	addi	a1,a1,618 # 800087e0 <syscalls+0x2c0>
    8000557e:	8552                	mv	a0,s4
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	c7a080e7          	jalr	-902(ra) # 800041fa <dirlink>
    80005588:	04054463          	bltz	a0,800055d0 <create+0x162>
    8000558c:	40d0                	lw	a2,4(s1)
    8000558e:	00003597          	auipc	a1,0x3
    80005592:	25a58593          	addi	a1,a1,602 # 800087e8 <syscalls+0x2c8>
    80005596:	8552                	mv	a0,s4
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	c62080e7          	jalr	-926(ra) # 800041fa <dirlink>
    800055a0:	02054863          	bltz	a0,800055d0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800055a4:	004a2603          	lw	a2,4(s4)
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	8526                	mv	a0,s1
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	c4c080e7          	jalr	-948(ra) # 800041fa <dirlink>
    800055b6:	00054d63          	bltz	a0,800055d0 <create+0x162>
    dp->nlink++;  // for ".."
    800055ba:	04a4d783          	lhu	a5,74(s1)
    800055be:	2785                	addiw	a5,a5,1
    800055c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	46e080e7          	jalr	1134(ra) # 80003a34 <iupdate>
    800055ce:	b761                	j	80005556 <create+0xe8>
  ip->nlink = 0;
    800055d0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055d4:	8552                	mv	a0,s4
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	45e080e7          	jalr	1118(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800055de:	8552                	mv	a0,s4
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	782080e7          	jalr	1922(ra) # 80003d62 <iunlockput>
  iunlockput(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	778080e7          	jalr	1912(ra) # 80003d62 <iunlockput>
  return 0;
    800055f2:	bdcd                	j	800054e4 <create+0x76>
    return 0;
    800055f4:	8aaa                	mv	s5,a0
    800055f6:	b5fd                	j	800054e4 <create+0x76>

00000000800055f8 <sys_dup>:
{
    800055f8:	7179                	addi	sp,sp,-48
    800055fa:	f406                	sd	ra,40(sp)
    800055fc:	f022                	sd	s0,32(sp)
    800055fe:	ec26                	sd	s1,24(sp)
    80005600:	e84a                	sd	s2,16(sp)
    80005602:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005604:	fd840613          	addi	a2,s0,-40
    80005608:	4581                	li	a1,0
    8000560a:	4501                	li	a0,0
    8000560c:	00000097          	auipc	ra,0x0
    80005610:	dc0080e7          	jalr	-576(ra) # 800053cc <argfd>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005616:	02054363          	bltz	a0,8000563c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000561a:	fd843903          	ld	s2,-40(s0)
    8000561e:	854a                	mv	a0,s2
    80005620:	00000097          	auipc	ra,0x0
    80005624:	e0c080e7          	jalr	-500(ra) # 8000542c <fdalloc>
    80005628:	84aa                	mv	s1,a0
    return -1;
    8000562a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000562c:	00054863          	bltz	a0,8000563c <sys_dup+0x44>
  filedup(f);
    80005630:	854a                	mv	a0,s2
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	310080e7          	jalr	784(ra) # 80004942 <filedup>
  return fd;
    8000563a:	87a6                	mv	a5,s1
}
    8000563c:	853e                	mv	a0,a5
    8000563e:	70a2                	ld	ra,40(sp)
    80005640:	7402                	ld	s0,32(sp)
    80005642:	64e2                	ld	s1,24(sp)
    80005644:	6942                	ld	s2,16(sp)
    80005646:	6145                	addi	sp,sp,48
    80005648:	8082                	ret

000000008000564a <sys_read>:
{
    8000564a:	7179                	addi	sp,sp,-48
    8000564c:	f406                	sd	ra,40(sp)
    8000564e:	f022                	sd	s0,32(sp)
    80005650:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005652:	fd840593          	addi	a1,s0,-40
    80005656:	4505                	li	a0,1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	8b2080e7          	jalr	-1870(ra) # 80002f0a <argaddr>
  argint(2, &n);
    80005660:	fe440593          	addi	a1,s0,-28
    80005664:	4509                	li	a0,2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	884080e7          	jalr	-1916(ra) # 80002eea <argint>
  if(argfd(0, 0, &f) < 0)
    8000566e:	fe840613          	addi	a2,s0,-24
    80005672:	4581                	li	a1,0
    80005674:	4501                	li	a0,0
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	d56080e7          	jalr	-682(ra) # 800053cc <argfd>
    8000567e:	87aa                	mv	a5,a0
    return -1;
    80005680:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005682:	0007cc63          	bltz	a5,8000569a <sys_read+0x50>
  return fileread(f, p, n);
    80005686:	fe442603          	lw	a2,-28(s0)
    8000568a:	fd843583          	ld	a1,-40(s0)
    8000568e:	fe843503          	ld	a0,-24(s0)
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	43c080e7          	jalr	1084(ra) # 80004ace <fileread>
}
    8000569a:	70a2                	ld	ra,40(sp)
    8000569c:	7402                	ld	s0,32(sp)
    8000569e:	6145                	addi	sp,sp,48
    800056a0:	8082                	ret

00000000800056a2 <sys_write>:
{
    800056a2:	7179                	addi	sp,sp,-48
    800056a4:	f406                	sd	ra,40(sp)
    800056a6:	f022                	sd	s0,32(sp)
    800056a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056aa:	fd840593          	addi	a1,s0,-40
    800056ae:	4505                	li	a0,1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	85a080e7          	jalr	-1958(ra) # 80002f0a <argaddr>
  argint(2, &n);
    800056b8:	fe440593          	addi	a1,s0,-28
    800056bc:	4509                	li	a0,2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	82c080e7          	jalr	-2004(ra) # 80002eea <argint>
  if(argfd(0, 0, &f) < 0)
    800056c6:	fe840613          	addi	a2,s0,-24
    800056ca:	4581                	li	a1,0
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	cfe080e7          	jalr	-770(ra) # 800053cc <argfd>
    800056d6:	87aa                	mv	a5,a0
    return -1;
    800056d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056da:	0007cc63          	bltz	a5,800056f2 <sys_write+0x50>
  return filewrite(f, p, n);
    800056de:	fe442603          	lw	a2,-28(s0)
    800056e2:	fd843583          	ld	a1,-40(s0)
    800056e6:	fe843503          	ld	a0,-24(s0)
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	4a6080e7          	jalr	1190(ra) # 80004b90 <filewrite>
}
    800056f2:	70a2                	ld	ra,40(sp)
    800056f4:	7402                	ld	s0,32(sp)
    800056f6:	6145                	addi	sp,sp,48
    800056f8:	8082                	ret

00000000800056fa <sys_close>:
{
    800056fa:	1101                	addi	sp,sp,-32
    800056fc:	ec06                	sd	ra,24(sp)
    800056fe:	e822                	sd	s0,16(sp)
    80005700:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005702:	fe040613          	addi	a2,s0,-32
    80005706:	fec40593          	addi	a1,s0,-20
    8000570a:	4501                	li	a0,0
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	cc0080e7          	jalr	-832(ra) # 800053cc <argfd>
    return -1;
    80005714:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005716:	02054463          	bltz	a0,8000573e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000571a:	ffffc097          	auipc	ra,0xffffc
    8000571e:	46a080e7          	jalr	1130(ra) # 80001b84 <myproc>
    80005722:	fec42783          	lw	a5,-20(s0)
    80005726:	07e9                	addi	a5,a5,26
    80005728:	078e                	slli	a5,a5,0x3
    8000572a:	953e                	add	a0,a0,a5
    8000572c:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005730:	fe043503          	ld	a0,-32(s0)
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	260080e7          	jalr	608(ra) # 80004994 <fileclose>
  return 0;
    8000573c:	4781                	li	a5,0
}
    8000573e:	853e                	mv	a0,a5
    80005740:	60e2                	ld	ra,24(sp)
    80005742:	6442                	ld	s0,16(sp)
    80005744:	6105                	addi	sp,sp,32
    80005746:	8082                	ret

0000000080005748 <sys_fstat>:
{
    80005748:	1101                	addi	sp,sp,-32
    8000574a:	ec06                	sd	ra,24(sp)
    8000574c:	e822                	sd	s0,16(sp)
    8000574e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005750:	fe040593          	addi	a1,s0,-32
    80005754:	4505                	li	a0,1
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	7b4080e7          	jalr	1972(ra) # 80002f0a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000575e:	fe840613          	addi	a2,s0,-24
    80005762:	4581                	li	a1,0
    80005764:	4501                	li	a0,0
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	c66080e7          	jalr	-922(ra) # 800053cc <argfd>
    8000576e:	87aa                	mv	a5,a0
    return -1;
    80005770:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005772:	0007ca63          	bltz	a5,80005786 <sys_fstat+0x3e>
  return filestat(f, st);
    80005776:	fe043583          	ld	a1,-32(s0)
    8000577a:	fe843503          	ld	a0,-24(s0)
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	2de080e7          	jalr	734(ra) # 80004a5c <filestat>
}
    80005786:	60e2                	ld	ra,24(sp)
    80005788:	6442                	ld	s0,16(sp)
    8000578a:	6105                	addi	sp,sp,32
    8000578c:	8082                	ret

000000008000578e <sys_link>:
{
    8000578e:	7169                	addi	sp,sp,-304
    80005790:	f606                	sd	ra,296(sp)
    80005792:	f222                	sd	s0,288(sp)
    80005794:	ee26                	sd	s1,280(sp)
    80005796:	ea4a                	sd	s2,272(sp)
    80005798:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579a:	08000613          	li	a2,128
    8000579e:	ed040593          	addi	a1,s0,-304
    800057a2:	4501                	li	a0,0
    800057a4:	ffffd097          	auipc	ra,0xffffd
    800057a8:	786080e7          	jalr	1926(ra) # 80002f2a <argstr>
    return -1;
    800057ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ae:	10054e63          	bltz	a0,800058ca <sys_link+0x13c>
    800057b2:	08000613          	li	a2,128
    800057b6:	f5040593          	addi	a1,s0,-176
    800057ba:	4505                	li	a0,1
    800057bc:	ffffd097          	auipc	ra,0xffffd
    800057c0:	76e080e7          	jalr	1902(ra) # 80002f2a <argstr>
    return -1;
    800057c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c6:	10054263          	bltz	a0,800058ca <sys_link+0x13c>
  begin_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	d02080e7          	jalr	-766(ra) # 800044cc <begin_op>
  if((ip = namei(old)) == 0){
    800057d2:	ed040513          	addi	a0,s0,-304
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	ad6080e7          	jalr	-1322(ra) # 800042ac <namei>
    800057de:	84aa                	mv	s1,a0
    800057e0:	c551                	beqz	a0,8000586c <sys_link+0xde>
  ilock(ip);
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	31e080e7          	jalr	798(ra) # 80003b00 <ilock>
  if(ip->type == T_DIR){
    800057ea:	04449703          	lh	a4,68(s1)
    800057ee:	4785                	li	a5,1
    800057f0:	08f70463          	beq	a4,a5,80005878 <sys_link+0xea>
  ip->nlink++;
    800057f4:	04a4d783          	lhu	a5,74(s1)
    800057f8:	2785                	addiw	a5,a5,1
    800057fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	234080e7          	jalr	564(ra) # 80003a34 <iupdate>
  iunlock(ip);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	3b8080e7          	jalr	952(ra) # 80003bc2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005812:	fd040593          	addi	a1,s0,-48
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	ab0080e7          	jalr	-1360(ra) # 800042ca <nameiparent>
    80005822:	892a                	mv	s2,a0
    80005824:	c935                	beqz	a0,80005898 <sys_link+0x10a>
  ilock(dp);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	2da080e7          	jalr	730(ra) # 80003b00 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000582e:	00092703          	lw	a4,0(s2)
    80005832:	409c                	lw	a5,0(s1)
    80005834:	04f71d63          	bne	a4,a5,8000588e <sys_link+0x100>
    80005838:	40d0                	lw	a2,4(s1)
    8000583a:	fd040593          	addi	a1,s0,-48
    8000583e:	854a                	mv	a0,s2
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	9ba080e7          	jalr	-1606(ra) # 800041fa <dirlink>
    80005848:	04054363          	bltz	a0,8000588e <sys_link+0x100>
  iunlockput(dp);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	514080e7          	jalr	1300(ra) # 80003d62 <iunlockput>
  iput(ip);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	462080e7          	jalr	1122(ra) # 80003cba <iput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	cea080e7          	jalr	-790(ra) # 8000454a <end_op>
  return 0;
    80005868:	4781                	li	a5,0
    8000586a:	a085                	j	800058ca <sys_link+0x13c>
    end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	cde080e7          	jalr	-802(ra) # 8000454a <end_op>
    return -1;
    80005874:	57fd                	li	a5,-1
    80005876:	a891                	j	800058ca <sys_link+0x13c>
    iunlockput(ip);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	4e8080e7          	jalr	1256(ra) # 80003d62 <iunlockput>
    end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	cc8080e7          	jalr	-824(ra) # 8000454a <end_op>
    return -1;
    8000588a:	57fd                	li	a5,-1
    8000588c:	a83d                	j	800058ca <sys_link+0x13c>
    iunlockput(dp);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	4d2080e7          	jalr	1234(ra) # 80003d62 <iunlockput>
  ilock(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	266080e7          	jalr	614(ra) # 80003b00 <ilock>
  ip->nlink--;
    800058a2:	04a4d783          	lhu	a5,74(s1)
    800058a6:	37fd                	addiw	a5,a5,-1
    800058a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	186080e7          	jalr	390(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	4aa080e7          	jalr	1194(ra) # 80003d62 <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	c8a080e7          	jalr	-886(ra) # 8000454a <end_op>
  return -1;
    800058c8:	57fd                	li	a5,-1
}
    800058ca:	853e                	mv	a0,a5
    800058cc:	70b2                	ld	ra,296(sp)
    800058ce:	7412                	ld	s0,288(sp)
    800058d0:	64f2                	ld	s1,280(sp)
    800058d2:	6952                	ld	s2,272(sp)
    800058d4:	6155                	addi	sp,sp,304
    800058d6:	8082                	ret

00000000800058d8 <sys_unlink>:
{
    800058d8:	7151                	addi	sp,sp,-240
    800058da:	f586                	sd	ra,232(sp)
    800058dc:	f1a2                	sd	s0,224(sp)
    800058de:	eda6                	sd	s1,216(sp)
    800058e0:	e9ca                	sd	s2,208(sp)
    800058e2:	e5ce                	sd	s3,200(sp)
    800058e4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	f3040593          	addi	a1,s0,-208
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	63a080e7          	jalr	1594(ra) # 80002f2a <argstr>
    800058f8:	18054163          	bltz	a0,80005a7a <sys_unlink+0x1a2>
  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	bd0080e7          	jalr	-1072(ra) # 800044cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005904:	fb040593          	addi	a1,s0,-80
    80005908:	f3040513          	addi	a0,s0,-208
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	9be080e7          	jalr	-1602(ra) # 800042ca <nameiparent>
    80005914:	84aa                	mv	s1,a0
    80005916:	c979                	beqz	a0,800059ec <sys_unlink+0x114>
  ilock(dp);
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	1e8080e7          	jalr	488(ra) # 80003b00 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005920:	00003597          	auipc	a1,0x3
    80005924:	ec058593          	addi	a1,a1,-320 # 800087e0 <syscalls+0x2c0>
    80005928:	fb040513          	addi	a0,s0,-80
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	69e080e7          	jalr	1694(ra) # 80003fca <namecmp>
    80005934:	14050a63          	beqz	a0,80005a88 <sys_unlink+0x1b0>
    80005938:	00003597          	auipc	a1,0x3
    8000593c:	eb058593          	addi	a1,a1,-336 # 800087e8 <syscalls+0x2c8>
    80005940:	fb040513          	addi	a0,s0,-80
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	686080e7          	jalr	1670(ra) # 80003fca <namecmp>
    8000594c:	12050e63          	beqz	a0,80005a88 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005950:	f2c40613          	addi	a2,s0,-212
    80005954:	fb040593          	addi	a1,s0,-80
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	68a080e7          	jalr	1674(ra) # 80003fe4 <dirlookup>
    80005962:	892a                	mv	s2,a0
    80005964:	12050263          	beqz	a0,80005a88 <sys_unlink+0x1b0>
  ilock(ip);
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	198080e7          	jalr	408(ra) # 80003b00 <ilock>
  if(ip->nlink < 1)
    80005970:	04a91783          	lh	a5,74(s2)
    80005974:	08f05263          	blez	a5,800059f8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005978:	04491703          	lh	a4,68(s2)
    8000597c:	4785                	li	a5,1
    8000597e:	08f70563          	beq	a4,a5,80005a08 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005982:	4641                	li	a2,16
    80005984:	4581                	li	a1,0
    80005986:	fc040513          	addi	a0,s0,-64
    8000598a:	ffffb097          	auipc	ra,0xffffb
    8000598e:	348080e7          	jalr	840(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005992:	4741                	li	a4,16
    80005994:	f2c42683          	lw	a3,-212(s0)
    80005998:	fc040613          	addi	a2,s0,-64
    8000599c:	4581                	li	a1,0
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	50c080e7          	jalr	1292(ra) # 80003eac <writei>
    800059a8:	47c1                	li	a5,16
    800059aa:	0af51563          	bne	a0,a5,80005a54 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059ae:	04491703          	lh	a4,68(s2)
    800059b2:	4785                	li	a5,1
    800059b4:	0af70863          	beq	a4,a5,80005a64 <sys_unlink+0x18c>
  iunlockput(dp);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	3a8080e7          	jalr	936(ra) # 80003d62 <iunlockput>
  ip->nlink--;
    800059c2:	04a95783          	lhu	a5,74(s2)
    800059c6:	37fd                	addiw	a5,a5,-1
    800059c8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	066080e7          	jalr	102(ra) # 80003a34 <iupdate>
  iunlockput(ip);
    800059d6:	854a                	mv	a0,s2
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	38a080e7          	jalr	906(ra) # 80003d62 <iunlockput>
  end_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	b6a080e7          	jalr	-1174(ra) # 8000454a <end_op>
  return 0;
    800059e8:	4501                	li	a0,0
    800059ea:	a84d                	j	80005a9c <sys_unlink+0x1c4>
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	b5e080e7          	jalr	-1186(ra) # 8000454a <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	a05d                	j	80005a9c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059f8:	00003517          	auipc	a0,0x3
    800059fc:	df850513          	addi	a0,a0,-520 # 800087f0 <syscalls+0x2d0>
    80005a00:	ffffb097          	auipc	ra,0xffffb
    80005a04:	b40080e7          	jalr	-1216(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a08:	04c92703          	lw	a4,76(s2)
    80005a0c:	02000793          	li	a5,32
    80005a10:	f6e7f9e3          	bgeu	a5,a4,80005982 <sys_unlink+0xaa>
    80005a14:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a18:	4741                	li	a4,16
    80005a1a:	86ce                	mv	a3,s3
    80005a1c:	f1840613          	addi	a2,s0,-232
    80005a20:	4581                	li	a1,0
    80005a22:	854a                	mv	a0,s2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	390080e7          	jalr	912(ra) # 80003db4 <readi>
    80005a2c:	47c1                	li	a5,16
    80005a2e:	00f51b63          	bne	a0,a5,80005a44 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a32:	f1845783          	lhu	a5,-232(s0)
    80005a36:	e7a1                	bnez	a5,80005a7e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a38:	29c1                	addiw	s3,s3,16
    80005a3a:	04c92783          	lw	a5,76(s2)
    80005a3e:	fcf9ede3          	bltu	s3,a5,80005a18 <sys_unlink+0x140>
    80005a42:	b781                	j	80005982 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a44:	00003517          	auipc	a0,0x3
    80005a48:	dc450513          	addi	a0,a0,-572 # 80008808 <syscalls+0x2e8>
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	af4080e7          	jalr	-1292(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a54:	00003517          	auipc	a0,0x3
    80005a58:	dcc50513          	addi	a0,a0,-564 # 80008820 <syscalls+0x300>
    80005a5c:	ffffb097          	auipc	ra,0xffffb
    80005a60:	ae4080e7          	jalr	-1308(ra) # 80000540 <panic>
    dp->nlink--;
    80005a64:	04a4d783          	lhu	a5,74(s1)
    80005a68:	37fd                	addiw	a5,a5,-1
    80005a6a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	fc4080e7          	jalr	-60(ra) # 80003a34 <iupdate>
    80005a78:	b781                	j	800059b8 <sys_unlink+0xe0>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	a005                	j	80005a9c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	2e2080e7          	jalr	738(ra) # 80003d62 <iunlockput>
  iunlockput(dp);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	2d8080e7          	jalr	728(ra) # 80003d62 <iunlockput>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	ab8080e7          	jalr	-1352(ra) # 8000454a <end_op>
  return -1;
    80005a9a:	557d                	li	a0,-1
}
    80005a9c:	70ae                	ld	ra,232(sp)
    80005a9e:	740e                	ld	s0,224(sp)
    80005aa0:	64ee                	ld	s1,216(sp)
    80005aa2:	694e                	ld	s2,208(sp)
    80005aa4:	69ae                	ld	s3,200(sp)
    80005aa6:	616d                	addi	sp,sp,240
    80005aa8:	8082                	ret

0000000080005aaa <sys_open>:

uint64
sys_open(void)
{
    80005aaa:	7131                	addi	sp,sp,-192
    80005aac:	fd06                	sd	ra,184(sp)
    80005aae:	f922                	sd	s0,176(sp)
    80005ab0:	f526                	sd	s1,168(sp)
    80005ab2:	f14a                	sd	s2,160(sp)
    80005ab4:	ed4e                	sd	s3,152(sp)
    80005ab6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ab8:	f4c40593          	addi	a1,s0,-180
    80005abc:	4505                	li	a0,1
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	42c080e7          	jalr	1068(ra) # 80002eea <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ac6:	08000613          	li	a2,128
    80005aca:	f5040593          	addi	a1,s0,-176
    80005ace:	4501                	li	a0,0
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	45a080e7          	jalr	1114(ra) # 80002f2a <argstr>
    80005ad8:	87aa                	mv	a5,a0
    return -1;
    80005ada:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005adc:	0a07c963          	bltz	a5,80005b8e <sys_open+0xe4>

  begin_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	9ec080e7          	jalr	-1556(ra) # 800044cc <begin_op>

  if(omode & O_CREATE){
    80005ae8:	f4c42783          	lw	a5,-180(s0)
    80005aec:	2007f793          	andi	a5,a5,512
    80005af0:	cfc5                	beqz	a5,80005ba8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005af2:	4681                	li	a3,0
    80005af4:	4601                	li	a2,0
    80005af6:	4589                	li	a1,2
    80005af8:	f5040513          	addi	a0,s0,-176
    80005afc:	00000097          	auipc	ra,0x0
    80005b00:	972080e7          	jalr	-1678(ra) # 8000546e <create>
    80005b04:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b06:	c959                	beqz	a0,80005b9c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	478d                	li	a5,3
    80005b0e:	00f71763          	bne	a4,a5,80005b1c <sys_open+0x72>
    80005b12:	0464d703          	lhu	a4,70(s1)
    80005b16:	47a5                	li	a5,9
    80005b18:	0ce7ed63          	bltu	a5,a4,80005bf2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	dbc080e7          	jalr	-580(ra) # 800048d8 <filealloc>
    80005b24:	89aa                	mv	s3,a0
    80005b26:	10050363          	beqz	a0,80005c2c <sys_open+0x182>
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	902080e7          	jalr	-1790(ra) # 8000542c <fdalloc>
    80005b32:	892a                	mv	s2,a0
    80005b34:	0e054763          	bltz	a0,80005c22 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b38:	04449703          	lh	a4,68(s1)
    80005b3c:	478d                	li	a5,3
    80005b3e:	0cf70563          	beq	a4,a5,80005c08 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b42:	4789                	li	a5,2
    80005b44:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b48:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b4c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b50:	f4c42783          	lw	a5,-180(s0)
    80005b54:	0017c713          	xori	a4,a5,1
    80005b58:	8b05                	andi	a4,a4,1
    80005b5a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b5e:	0037f713          	andi	a4,a5,3
    80005b62:	00e03733          	snez	a4,a4
    80005b66:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b6a:	4007f793          	andi	a5,a5,1024
    80005b6e:	c791                	beqz	a5,80005b7a <sys_open+0xd0>
    80005b70:	04449703          	lh	a4,68(s1)
    80005b74:	4789                	li	a5,2
    80005b76:	0af70063          	beq	a4,a5,80005c16 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	046080e7          	jalr	70(ra) # 80003bc2 <iunlock>
  end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	9c6080e7          	jalr	-1594(ra) # 8000454a <end_op>

  return fd;
    80005b8c:	854a                	mv	a0,s2
}
    80005b8e:	70ea                	ld	ra,184(sp)
    80005b90:	744a                	ld	s0,176(sp)
    80005b92:	74aa                	ld	s1,168(sp)
    80005b94:	790a                	ld	s2,160(sp)
    80005b96:	69ea                	ld	s3,152(sp)
    80005b98:	6129                	addi	sp,sp,192
    80005b9a:	8082                	ret
      end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	9ae080e7          	jalr	-1618(ra) # 8000454a <end_op>
      return -1;
    80005ba4:	557d                	li	a0,-1
    80005ba6:	b7e5                	j	80005b8e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ba8:	f5040513          	addi	a0,s0,-176
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	700080e7          	jalr	1792(ra) # 800042ac <namei>
    80005bb4:	84aa                	mv	s1,a0
    80005bb6:	c905                	beqz	a0,80005be6 <sys_open+0x13c>
    ilock(ip);
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	f48080e7          	jalr	-184(ra) # 80003b00 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bc0:	04449703          	lh	a4,68(s1)
    80005bc4:	4785                	li	a5,1
    80005bc6:	f4f711e3          	bne	a4,a5,80005b08 <sys_open+0x5e>
    80005bca:	f4c42783          	lw	a5,-180(s0)
    80005bce:	d7b9                	beqz	a5,80005b1c <sys_open+0x72>
      iunlockput(ip);
    80005bd0:	8526                	mv	a0,s1
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	190080e7          	jalr	400(ra) # 80003d62 <iunlockput>
      end_op();
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	970080e7          	jalr	-1680(ra) # 8000454a <end_op>
      return -1;
    80005be2:	557d                	li	a0,-1
    80005be4:	b76d                	j	80005b8e <sys_open+0xe4>
      end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	964080e7          	jalr	-1692(ra) # 8000454a <end_op>
      return -1;
    80005bee:	557d                	li	a0,-1
    80005bf0:	bf79                	j	80005b8e <sys_open+0xe4>
    iunlockput(ip);
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	16e080e7          	jalr	366(ra) # 80003d62 <iunlockput>
    end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	94e080e7          	jalr	-1714(ra) # 8000454a <end_op>
    return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	b761                	j	80005b8e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c08:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c0c:	04649783          	lh	a5,70(s1)
    80005c10:	02f99223          	sh	a5,36(s3)
    80005c14:	bf25                	j	80005b4c <sys_open+0xa2>
    itrunc(ip);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	ff6080e7          	jalr	-10(ra) # 80003c0e <itrunc>
    80005c20:	bfa9                	j	80005b7a <sys_open+0xd0>
      fileclose(f);
    80005c22:	854e                	mv	a0,s3
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	d70080e7          	jalr	-656(ra) # 80004994 <fileclose>
    iunlockput(ip);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	134080e7          	jalr	308(ra) # 80003d62 <iunlockput>
    end_op();
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	914080e7          	jalr	-1772(ra) # 8000454a <end_op>
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	b7b9                	j	80005b8e <sys_open+0xe4>

0000000080005c42 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c42:	7175                	addi	sp,sp,-144
    80005c44:	e506                	sd	ra,136(sp)
    80005c46:	e122                	sd	s0,128(sp)
    80005c48:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	882080e7          	jalr	-1918(ra) # 800044cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c52:	08000613          	li	a2,128
    80005c56:	f7040593          	addi	a1,s0,-144
    80005c5a:	4501                	li	a0,0
    80005c5c:	ffffd097          	auipc	ra,0xffffd
    80005c60:	2ce080e7          	jalr	718(ra) # 80002f2a <argstr>
    80005c64:	02054963          	bltz	a0,80005c96 <sys_mkdir+0x54>
    80005c68:	4681                	li	a3,0
    80005c6a:	4601                	li	a2,0
    80005c6c:	4585                	li	a1,1
    80005c6e:	f7040513          	addi	a0,s0,-144
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	7fc080e7          	jalr	2044(ra) # 8000546e <create>
    80005c7a:	cd11                	beqz	a0,80005c96 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	0e6080e7          	jalr	230(ra) # 80003d62 <iunlockput>
  end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	8c6080e7          	jalr	-1850(ra) # 8000454a <end_op>
  return 0;
    80005c8c:	4501                	li	a0,0
}
    80005c8e:	60aa                	ld	ra,136(sp)
    80005c90:	640a                	ld	s0,128(sp)
    80005c92:	6149                	addi	sp,sp,144
    80005c94:	8082                	ret
    end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	8b4080e7          	jalr	-1868(ra) # 8000454a <end_op>
    return -1;
    80005c9e:	557d                	li	a0,-1
    80005ca0:	b7fd                	j	80005c8e <sys_mkdir+0x4c>

0000000080005ca2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ca2:	7135                	addi	sp,sp,-160
    80005ca4:	ed06                	sd	ra,152(sp)
    80005ca6:	e922                	sd	s0,144(sp)
    80005ca8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	822080e7          	jalr	-2014(ra) # 800044cc <begin_op>
  argint(1, &major);
    80005cb2:	f6c40593          	addi	a1,s0,-148
    80005cb6:	4505                	li	a0,1
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	232080e7          	jalr	562(ra) # 80002eea <argint>
  argint(2, &minor);
    80005cc0:	f6840593          	addi	a1,s0,-152
    80005cc4:	4509                	li	a0,2
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	224080e7          	jalr	548(ra) # 80002eea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cce:	08000613          	li	a2,128
    80005cd2:	f7040593          	addi	a1,s0,-144
    80005cd6:	4501                	li	a0,0
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	252080e7          	jalr	594(ra) # 80002f2a <argstr>
    80005ce0:	02054b63          	bltz	a0,80005d16 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ce4:	f6841683          	lh	a3,-152(s0)
    80005ce8:	f6c41603          	lh	a2,-148(s0)
    80005cec:	458d                	li	a1,3
    80005cee:	f7040513          	addi	a0,s0,-144
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	77c080e7          	jalr	1916(ra) # 8000546e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfa:	cd11                	beqz	a0,80005d16 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	066080e7          	jalr	102(ra) # 80003d62 <iunlockput>
  end_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	846080e7          	jalr	-1978(ra) # 8000454a <end_op>
  return 0;
    80005d0c:	4501                	li	a0,0
}
    80005d0e:	60ea                	ld	ra,152(sp)
    80005d10:	644a                	ld	s0,144(sp)
    80005d12:	610d                	addi	sp,sp,160
    80005d14:	8082                	ret
    end_op();
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	834080e7          	jalr	-1996(ra) # 8000454a <end_op>
    return -1;
    80005d1e:	557d                	li	a0,-1
    80005d20:	b7fd                	j	80005d0e <sys_mknod+0x6c>

0000000080005d22 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d22:	7135                	addi	sp,sp,-160
    80005d24:	ed06                	sd	ra,152(sp)
    80005d26:	e922                	sd	s0,144(sp)
    80005d28:	e526                	sd	s1,136(sp)
    80005d2a:	e14a                	sd	s2,128(sp)
    80005d2c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d2e:	ffffc097          	auipc	ra,0xffffc
    80005d32:	e56080e7          	jalr	-426(ra) # 80001b84 <myproc>
    80005d36:	892a                	mv	s2,a0
  
  begin_op();
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	794080e7          	jalr	1940(ra) # 800044cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d40:	08000613          	li	a2,128
    80005d44:	f6040593          	addi	a1,s0,-160
    80005d48:	4501                	li	a0,0
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	1e0080e7          	jalr	480(ra) # 80002f2a <argstr>
    80005d52:	04054b63          	bltz	a0,80005da8 <sys_chdir+0x86>
    80005d56:	f6040513          	addi	a0,s0,-160
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	552080e7          	jalr	1362(ra) # 800042ac <namei>
    80005d62:	84aa                	mv	s1,a0
    80005d64:	c131                	beqz	a0,80005da8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	d9a080e7          	jalr	-614(ra) # 80003b00 <ilock>
  if(ip->type != T_DIR){
    80005d6e:	04449703          	lh	a4,68(s1)
    80005d72:	4785                	li	a5,1
    80005d74:	04f71063          	bne	a4,a5,80005db4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d78:	8526                	mv	a0,s1
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	e48080e7          	jalr	-440(ra) # 80003bc2 <iunlock>
  iput(p->cwd);
    80005d82:	15893503          	ld	a0,344(s2)
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	f34080e7          	jalr	-204(ra) # 80003cba <iput>
  end_op();
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	7bc080e7          	jalr	1980(ra) # 8000454a <end_op>
  p->cwd = ip;
    80005d96:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d9a:	4501                	li	a0,0
}
    80005d9c:	60ea                	ld	ra,152(sp)
    80005d9e:	644a                	ld	s0,144(sp)
    80005da0:	64aa                	ld	s1,136(sp)
    80005da2:	690a                	ld	s2,128(sp)
    80005da4:	610d                	addi	sp,sp,160
    80005da6:	8082                	ret
    end_op();
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	7a2080e7          	jalr	1954(ra) # 8000454a <end_op>
    return -1;
    80005db0:	557d                	li	a0,-1
    80005db2:	b7ed                	j	80005d9c <sys_chdir+0x7a>
    iunlockput(ip);
    80005db4:	8526                	mv	a0,s1
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	fac080e7          	jalr	-84(ra) # 80003d62 <iunlockput>
    end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	78c080e7          	jalr	1932(ra) # 8000454a <end_op>
    return -1;
    80005dc6:	557d                	li	a0,-1
    80005dc8:	bfd1                	j	80005d9c <sys_chdir+0x7a>

0000000080005dca <sys_exec>:

uint64
sys_exec(void)
{
    80005dca:	7145                	addi	sp,sp,-464
    80005dcc:	e786                	sd	ra,456(sp)
    80005dce:	e3a2                	sd	s0,448(sp)
    80005dd0:	ff26                	sd	s1,440(sp)
    80005dd2:	fb4a                	sd	s2,432(sp)
    80005dd4:	f74e                	sd	s3,424(sp)
    80005dd6:	f352                	sd	s4,416(sp)
    80005dd8:	ef56                	sd	s5,408(sp)
    80005dda:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ddc:	e3840593          	addi	a1,s0,-456
    80005de0:	4505                	li	a0,1
    80005de2:	ffffd097          	auipc	ra,0xffffd
    80005de6:	128080e7          	jalr	296(ra) # 80002f0a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dea:	08000613          	li	a2,128
    80005dee:	f4040593          	addi	a1,s0,-192
    80005df2:	4501                	li	a0,0
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	136080e7          	jalr	310(ra) # 80002f2a <argstr>
    80005dfc:	87aa                	mv	a5,a0
    return -1;
    80005dfe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e00:	0c07c363          	bltz	a5,80005ec6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e04:	10000613          	li	a2,256
    80005e08:	4581                	li	a1,0
    80005e0a:	e4040513          	addi	a0,s0,-448
    80005e0e:	ffffb097          	auipc	ra,0xffffb
    80005e12:	ec4080e7          	jalr	-316(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e1a:	89a6                	mv	s3,s1
    80005e1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e1e:	02000a13          	li	s4,32
    80005e22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e26:	00391513          	slli	a0,s2,0x3
    80005e2a:	e3040593          	addi	a1,s0,-464
    80005e2e:	e3843783          	ld	a5,-456(s0)
    80005e32:	953e                	add	a0,a0,a5
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	018080e7          	jalr	24(ra) # 80002e4c <fetchaddr>
    80005e3c:	02054a63          	bltz	a0,80005e70 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e40:	e3043783          	ld	a5,-464(s0)
    80005e44:	c3b9                	beqz	a5,80005e8a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e46:	ffffb097          	auipc	ra,0xffffb
    80005e4a:	ca0080e7          	jalr	-864(ra) # 80000ae6 <kalloc>
    80005e4e:	85aa                	mv	a1,a0
    80005e50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e54:	cd11                	beqz	a0,80005e70 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e56:	6605                	lui	a2,0x1
    80005e58:	e3043503          	ld	a0,-464(s0)
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	042080e7          	jalr	66(ra) # 80002e9e <fetchstr>
    80005e64:	00054663          	bltz	a0,80005e70 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e68:	0905                	addi	s2,s2,1
    80005e6a:	09a1                	addi	s3,s3,8
    80005e6c:	fb491be3          	bne	s2,s4,80005e22 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e70:	f4040913          	addi	s2,s0,-192
    80005e74:	6088                	ld	a0,0(s1)
    80005e76:	c539                	beqz	a0,80005ec4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e78:	ffffb097          	auipc	ra,0xffffb
    80005e7c:	b70080e7          	jalr	-1168(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e80:	04a1                	addi	s1,s1,8
    80005e82:	ff2499e3          	bne	s1,s2,80005e74 <sys_exec+0xaa>
  return -1;
    80005e86:	557d                	li	a0,-1
    80005e88:	a83d                	j	80005ec6 <sys_exec+0xfc>
      argv[i] = 0;
    80005e8a:	0a8e                	slli	s5,s5,0x3
    80005e8c:	fc0a8793          	addi	a5,s5,-64
    80005e90:	00878ab3          	add	s5,a5,s0
    80005e94:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e98:	e4040593          	addi	a1,s0,-448
    80005e9c:	f4040513          	addi	a0,s0,-192
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	16e080e7          	jalr	366(ra) # 8000500e <exec>
    80005ea8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eaa:	f4040993          	addi	s3,s0,-192
    80005eae:	6088                	ld	a0,0(s1)
    80005eb0:	c901                	beqz	a0,80005ec0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	b36080e7          	jalr	-1226(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eba:	04a1                	addi	s1,s1,8
    80005ebc:	ff3499e3          	bne	s1,s3,80005eae <sys_exec+0xe4>
  return ret;
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	a011                	j	80005ec6 <sys_exec+0xfc>
  return -1;
    80005ec4:	557d                	li	a0,-1
}
    80005ec6:	60be                	ld	ra,456(sp)
    80005ec8:	641e                	ld	s0,448(sp)
    80005eca:	74fa                	ld	s1,440(sp)
    80005ecc:	795a                	ld	s2,432(sp)
    80005ece:	79ba                	ld	s3,424(sp)
    80005ed0:	7a1a                	ld	s4,416(sp)
    80005ed2:	6afa                	ld	s5,408(sp)
    80005ed4:	6179                	addi	sp,sp,464
    80005ed6:	8082                	ret

0000000080005ed8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ed8:	7139                	addi	sp,sp,-64
    80005eda:	fc06                	sd	ra,56(sp)
    80005edc:	f822                	sd	s0,48(sp)
    80005ede:	f426                	sd	s1,40(sp)
    80005ee0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ee2:	ffffc097          	auipc	ra,0xffffc
    80005ee6:	ca2080e7          	jalr	-862(ra) # 80001b84 <myproc>
    80005eea:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005eec:	fd840593          	addi	a1,s0,-40
    80005ef0:	4501                	li	a0,0
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	018080e7          	jalr	24(ra) # 80002f0a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005efa:	fc840593          	addi	a1,s0,-56
    80005efe:	fd040513          	addi	a0,s0,-48
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	dc2080e7          	jalr	-574(ra) # 80004cc4 <pipealloc>
    return -1;
    80005f0a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f0c:	0c054463          	bltz	a0,80005fd4 <sys_pipe+0xfc>
  fd0 = -1;
    80005f10:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f14:	fd043503          	ld	a0,-48(s0)
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	514080e7          	jalr	1300(ra) # 8000542c <fdalloc>
    80005f20:	fca42223          	sw	a0,-60(s0)
    80005f24:	08054b63          	bltz	a0,80005fba <sys_pipe+0xe2>
    80005f28:	fc843503          	ld	a0,-56(s0)
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	500080e7          	jalr	1280(ra) # 8000542c <fdalloc>
    80005f34:	fca42023          	sw	a0,-64(s0)
    80005f38:	06054863          	bltz	a0,80005fa8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f3c:	4691                	li	a3,4
    80005f3e:	fc440613          	addi	a2,s0,-60
    80005f42:	fd843583          	ld	a1,-40(s0)
    80005f46:	6ca8                	ld	a0,88(s1)
    80005f48:	ffffb097          	auipc	ra,0xffffb
    80005f4c:	724080e7          	jalr	1828(ra) # 8000166c <copyout>
    80005f50:	02054063          	bltz	a0,80005f70 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f54:	4691                	li	a3,4
    80005f56:	fc040613          	addi	a2,s0,-64
    80005f5a:	fd843583          	ld	a1,-40(s0)
    80005f5e:	0591                	addi	a1,a1,4
    80005f60:	6ca8                	ld	a0,88(s1)
    80005f62:	ffffb097          	auipc	ra,0xffffb
    80005f66:	70a080e7          	jalr	1802(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f6a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f6c:	06055463          	bgez	a0,80005fd4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f70:	fc442783          	lw	a5,-60(s0)
    80005f74:	07e9                	addi	a5,a5,26
    80005f76:	078e                	slli	a5,a5,0x3
    80005f78:	97a6                	add	a5,a5,s1
    80005f7a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f7e:	fc042783          	lw	a5,-64(s0)
    80005f82:	07e9                	addi	a5,a5,26
    80005f84:	078e                	slli	a5,a5,0x3
    80005f86:	94be                	add	s1,s1,a5
    80005f88:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005f8c:	fd043503          	ld	a0,-48(s0)
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	a04080e7          	jalr	-1532(ra) # 80004994 <fileclose>
    fileclose(wf);
    80005f98:	fc843503          	ld	a0,-56(s0)
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	9f8080e7          	jalr	-1544(ra) # 80004994 <fileclose>
    return -1;
    80005fa4:	57fd                	li	a5,-1
    80005fa6:	a03d                	j	80005fd4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fa8:	fc442783          	lw	a5,-60(s0)
    80005fac:	0007c763          	bltz	a5,80005fba <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fb0:	07e9                	addi	a5,a5,26
    80005fb2:	078e                	slli	a5,a5,0x3
    80005fb4:	97a6                	add	a5,a5,s1
    80005fb6:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005fba:	fd043503          	ld	a0,-48(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	9d6080e7          	jalr	-1578(ra) # 80004994 <fileclose>
    fileclose(wf);
    80005fc6:	fc843503          	ld	a0,-56(s0)
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	9ca080e7          	jalr	-1590(ra) # 80004994 <fileclose>
    return -1;
    80005fd2:	57fd                	li	a5,-1
}
    80005fd4:	853e                	mv	a0,a5
    80005fd6:	70e2                	ld	ra,56(sp)
    80005fd8:	7442                	ld	s0,48(sp)
    80005fda:	74a2                	ld	s1,40(sp)
    80005fdc:	6121                	addi	sp,sp,64
    80005fde:	8082                	ret

0000000080005fe0 <kernelvec>:
    80005fe0:	7111                	addi	sp,sp,-256
    80005fe2:	e006                	sd	ra,0(sp)
    80005fe4:	e40a                	sd	sp,8(sp)
    80005fe6:	e80e                	sd	gp,16(sp)
    80005fe8:	ec12                	sd	tp,24(sp)
    80005fea:	f016                	sd	t0,32(sp)
    80005fec:	f41a                	sd	t1,40(sp)
    80005fee:	f81e                	sd	t2,48(sp)
    80005ff0:	fc22                	sd	s0,56(sp)
    80005ff2:	e0a6                	sd	s1,64(sp)
    80005ff4:	e4aa                	sd	a0,72(sp)
    80005ff6:	e8ae                	sd	a1,80(sp)
    80005ff8:	ecb2                	sd	a2,88(sp)
    80005ffa:	f0b6                	sd	a3,96(sp)
    80005ffc:	f4ba                	sd	a4,104(sp)
    80005ffe:	f8be                	sd	a5,112(sp)
    80006000:	fcc2                	sd	a6,120(sp)
    80006002:	e146                	sd	a7,128(sp)
    80006004:	e54a                	sd	s2,136(sp)
    80006006:	e94e                	sd	s3,144(sp)
    80006008:	ed52                	sd	s4,152(sp)
    8000600a:	f156                	sd	s5,160(sp)
    8000600c:	f55a                	sd	s6,168(sp)
    8000600e:	f95e                	sd	s7,176(sp)
    80006010:	fd62                	sd	s8,184(sp)
    80006012:	e1e6                	sd	s9,192(sp)
    80006014:	e5ea                	sd	s10,200(sp)
    80006016:	e9ee                	sd	s11,208(sp)
    80006018:	edf2                	sd	t3,216(sp)
    8000601a:	f1f6                	sd	t4,224(sp)
    8000601c:	f5fa                	sd	t5,232(sp)
    8000601e:	f9fe                	sd	t6,240(sp)
    80006020:	cf7fc0ef          	jal	ra,80002d16 <kerneltrap>
    80006024:	6082                	ld	ra,0(sp)
    80006026:	6122                	ld	sp,8(sp)
    80006028:	61c2                	ld	gp,16(sp)
    8000602a:	7282                	ld	t0,32(sp)
    8000602c:	7322                	ld	t1,40(sp)
    8000602e:	73c2                	ld	t2,48(sp)
    80006030:	7462                	ld	s0,56(sp)
    80006032:	6486                	ld	s1,64(sp)
    80006034:	6526                	ld	a0,72(sp)
    80006036:	65c6                	ld	a1,80(sp)
    80006038:	6666                	ld	a2,88(sp)
    8000603a:	7686                	ld	a3,96(sp)
    8000603c:	7726                	ld	a4,104(sp)
    8000603e:	77c6                	ld	a5,112(sp)
    80006040:	7866                	ld	a6,120(sp)
    80006042:	688a                	ld	a7,128(sp)
    80006044:	692a                	ld	s2,136(sp)
    80006046:	69ca                	ld	s3,144(sp)
    80006048:	6a6a                	ld	s4,152(sp)
    8000604a:	7a8a                	ld	s5,160(sp)
    8000604c:	7b2a                	ld	s6,168(sp)
    8000604e:	7bca                	ld	s7,176(sp)
    80006050:	7c6a                	ld	s8,184(sp)
    80006052:	6c8e                	ld	s9,192(sp)
    80006054:	6d2e                	ld	s10,200(sp)
    80006056:	6dce                	ld	s11,208(sp)
    80006058:	6e6e                	ld	t3,216(sp)
    8000605a:	7e8e                	ld	t4,224(sp)
    8000605c:	7f2e                	ld	t5,232(sp)
    8000605e:	7fce                	ld	t6,240(sp)
    80006060:	6111                	addi	sp,sp,256
    80006062:	10200073          	sret
    80006066:	00000013          	nop
    8000606a:	00000013          	nop
    8000606e:	0001                	nop

0000000080006070 <timervec>:
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	e10c                	sd	a1,0(a0)
    80006076:	e510                	sd	a2,8(a0)
    80006078:	e914                	sd	a3,16(a0)
    8000607a:	6d0c                	ld	a1,24(a0)
    8000607c:	7110                	ld	a2,32(a0)
    8000607e:	6194                	ld	a3,0(a1)
    80006080:	96b2                	add	a3,a3,a2
    80006082:	e194                	sd	a3,0(a1)
    80006084:	4589                	li	a1,2
    80006086:	14459073          	csrw	sip,a1
    8000608a:	6914                	ld	a3,16(a0)
    8000608c:	6510                	ld	a2,8(a0)
    8000608e:	610c                	ld	a1,0(a0)
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	30200073          	mret
	...

000000008000609a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000609a:	1141                	addi	sp,sp,-16
    8000609c:	e422                	sd	s0,8(sp)
    8000609e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060a0:	0c0007b7          	lui	a5,0xc000
    800060a4:	4705                	li	a4,1
    800060a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060a8:	c3d8                	sw	a4,4(a5)
}
    800060aa:	6422                	ld	s0,8(sp)
    800060ac:	0141                	addi	sp,sp,16
    800060ae:	8082                	ret

00000000800060b0 <plicinithart>:

void
plicinithart(void)
{
    800060b0:	1141                	addi	sp,sp,-16
    800060b2:	e406                	sd	ra,8(sp)
    800060b4:	e022                	sd	s0,0(sp)
    800060b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	aa0080e7          	jalr	-1376(ra) # 80001b58 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060c0:	0085171b          	slliw	a4,a0,0x8
    800060c4:	0c0027b7          	lui	a5,0xc002
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	40200713          	li	a4,1026
    800060ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060d2:	00d5151b          	slliw	a0,a0,0xd
    800060d6:	0c2017b7          	lui	a5,0xc201
    800060da:	97aa                	add	a5,a5,a0
    800060dc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret

00000000800060e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f0:	ffffc097          	auipc	ra,0xffffc
    800060f4:	a68080e7          	jalr	-1432(ra) # 80001b58 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060f8:	00d5151b          	slliw	a0,a0,0xd
    800060fc:	0c2017b7          	lui	a5,0xc201
    80006100:	97aa                	add	a5,a5,a0
  return irq;
}
    80006102:	43c8                	lw	a0,4(a5)
    80006104:	60a2                	ld	ra,8(sp)
    80006106:	6402                	ld	s0,0(sp)
    80006108:	0141                	addi	sp,sp,16
    8000610a:	8082                	ret

000000008000610c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	1000                	addi	s0,sp,32
    80006116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	a40080e7          	jalr	-1472(ra) # 80001b58 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006120:	00d5151b          	slliw	a0,a0,0xd
    80006124:	0c2017b7          	lui	a5,0xc201
    80006128:	97aa                	add	a5,a5,a0
    8000612a:	c3c4                	sw	s1,4(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret

0000000080006136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006136:	1141                	addi	sp,sp,-16
    80006138:	e406                	sd	ra,8(sp)
    8000613a:	e022                	sd	s0,0(sp)
    8000613c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000613e:	479d                	li	a5,7
    80006140:	04a7cc63          	blt	a5,a0,80006198 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006144:	0001c797          	auipc	a5,0x1c
    80006148:	e1c78793          	addi	a5,a5,-484 # 80021f60 <disk>
    8000614c:	97aa                	add	a5,a5,a0
    8000614e:	0187c783          	lbu	a5,24(a5)
    80006152:	ebb9                	bnez	a5,800061a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006154:	00451693          	slli	a3,a0,0x4
    80006158:	0001c797          	auipc	a5,0x1c
    8000615c:	e0878793          	addi	a5,a5,-504 # 80021f60 <disk>
    80006160:	6398                	ld	a4,0(a5)
    80006162:	9736                	add	a4,a4,a3
    80006164:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006168:	6398                	ld	a4,0(a5)
    8000616a:	9736                	add	a4,a4,a3
    8000616c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006170:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006174:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	4705                	li	a4,1
    8000617c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006180:	0001c517          	auipc	a0,0x1c
    80006184:	df850513          	addi	a0,a0,-520 # 80021f78 <disk+0x18>
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	20e080e7          	jalr	526(ra) # 80002396 <wakeup>
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret
    panic("free_desc 1");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	69850513          	addi	a0,a0,1688 # 80008830 <syscalls+0x310>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a0080e7          	jalr	928(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	69850513          	addi	a0,a0,1688 # 80008840 <syscalls+0x320>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	390080e7          	jalr	912(ra) # 80000540 <panic>

00000000800061b8 <virtio_disk_init>:
{
    800061b8:	1101                	addi	sp,sp,-32
    800061ba:	ec06                	sd	ra,24(sp)
    800061bc:	e822                	sd	s0,16(sp)
    800061be:	e426                	sd	s1,8(sp)
    800061c0:	e04a                	sd	s2,0(sp)
    800061c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061c4:	00002597          	auipc	a1,0x2
    800061c8:	68c58593          	addi	a1,a1,1676 # 80008850 <syscalls+0x330>
    800061cc:	0001c517          	auipc	a0,0x1c
    800061d0:	ebc50513          	addi	a0,a0,-324 # 80022088 <disk+0x128>
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	972080e7          	jalr	-1678(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061dc:	100017b7          	lui	a5,0x10001
    800061e0:	4398                	lw	a4,0(a5)
    800061e2:	2701                	sext.w	a4,a4
    800061e4:	747277b7          	lui	a5,0x74727
    800061e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ec:	14f71b63          	bne	a4,a5,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061f0:	100017b7          	lui	a5,0x10001
    800061f4:	43dc                	lw	a5,4(a5)
    800061f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f8:	4709                	li	a4,2
    800061fa:	14e79463          	bne	a5,a4,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061fe:	100017b7          	lui	a5,0x10001
    80006202:	479c                	lw	a5,8(a5)
    80006204:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006206:	12e79e63          	bne	a5,a4,80006342 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000620a:	100017b7          	lui	a5,0x10001
    8000620e:	47d8                	lw	a4,12(a5)
    80006210:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006212:	554d47b7          	lui	a5,0x554d4
    80006216:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000621a:	12f71463          	bne	a4,a5,80006342 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006226:	4705                	li	a4,1
    80006228:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622a:	470d                	li	a4,3
    8000622c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000622e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006230:	c7ffe6b7          	lui	a3,0xc7ffe
    80006234:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc6bf>
    80006238:	8f75                	and	a4,a4,a3
    8000623a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623c:	472d                	li	a4,11
    8000623e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006240:	5bbc                	lw	a5,112(a5)
    80006242:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006246:	8ba1                	andi	a5,a5,8
    80006248:	10078563          	beqz	a5,80006352 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000624c:	100017b7          	lui	a5,0x10001
    80006250:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006254:	43fc                	lw	a5,68(a5)
    80006256:	2781                	sext.w	a5,a5
    80006258:	10079563          	bnez	a5,80006362 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	5bdc                	lw	a5,52(a5)
    80006262:	2781                	sext.w	a5,a5
  if(max == 0)
    80006264:	10078763          	beqz	a5,80006372 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006268:	471d                	li	a4,7
    8000626a:	10f77c63          	bgeu	a4,a5,80006382 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	878080e7          	jalr	-1928(ra) # 80000ae6 <kalloc>
    80006276:	0001c497          	auipc	s1,0x1c
    8000627a:	cea48493          	addi	s1,s1,-790 # 80021f60 <disk>
    8000627e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	866080e7          	jalr	-1946(ra) # 80000ae6 <kalloc>
    80006288:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	85c080e7          	jalr	-1956(ra) # 80000ae6 <kalloc>
    80006292:	87aa                	mv	a5,a0
    80006294:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006296:	6088                	ld	a0,0(s1)
    80006298:	cd6d                	beqz	a0,80006392 <virtio_disk_init+0x1da>
    8000629a:	0001c717          	auipc	a4,0x1c
    8000629e:	cce73703          	ld	a4,-818(a4) # 80021f68 <disk+0x8>
    800062a2:	cb65                	beqz	a4,80006392 <virtio_disk_init+0x1da>
    800062a4:	c7fd                	beqz	a5,80006392 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062a6:	6605                	lui	a2,0x1
    800062a8:	4581                	li	a1,0
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	a28080e7          	jalr	-1496(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062b2:	0001c497          	auipc	s1,0x1c
    800062b6:	cae48493          	addi	s1,s1,-850 # 80021f60 <disk>
    800062ba:	6605                	lui	a2,0x1
    800062bc:	4581                	li	a1,0
    800062be:	6488                	ld	a0,8(s1)
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	a12080e7          	jalr	-1518(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800062c8:	6605                	lui	a2,0x1
    800062ca:	4581                	li	a1,0
    800062cc:	6888                	ld	a0,16(s1)
    800062ce:	ffffb097          	auipc	ra,0xffffb
    800062d2:	a04080e7          	jalr	-1532(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062d6:	100017b7          	lui	a5,0x10001
    800062da:	4721                	li	a4,8
    800062dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062de:	4098                	lw	a4,0(s1)
    800062e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062e4:	40d8                	lw	a4,4(s1)
    800062e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ea:	6498                	ld	a4,8(s1)
    800062ec:	0007069b          	sext.w	a3,a4
    800062f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062f4:	9701                	srai	a4,a4,0x20
    800062f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062fa:	6898                	ld	a4,16(s1)
    800062fc:	0007069b          	sext.w	a3,a4
    80006300:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006304:	9701                	srai	a4,a4,0x20
    80006306:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000630a:	4705                	li	a4,1
    8000630c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000630e:	00e48c23          	sb	a4,24(s1)
    80006312:	00e48ca3          	sb	a4,25(s1)
    80006316:	00e48d23          	sb	a4,26(s1)
    8000631a:	00e48da3          	sb	a4,27(s1)
    8000631e:	00e48e23          	sb	a4,28(s1)
    80006322:	00e48ea3          	sb	a4,29(s1)
    80006326:	00e48f23          	sb	a4,30(s1)
    8000632a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000632e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006332:	0727a823          	sw	s2,112(a5)
}
    80006336:	60e2                	ld	ra,24(sp)
    80006338:	6442                	ld	s0,16(sp)
    8000633a:	64a2                	ld	s1,8(sp)
    8000633c:	6902                	ld	s2,0(sp)
    8000633e:	6105                	addi	sp,sp,32
    80006340:	8082                	ret
    panic("could not find virtio disk");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	51e50513          	addi	a0,a0,1310 # 80008860 <syscalls+0x340>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	52e50513          	addi	a0,a0,1326 # 80008880 <syscalls+0x360>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	53e50513          	addi	a0,a0,1342 # 800088a0 <syscalls+0x380>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	54e50513          	addi	a0,a0,1358 # 800088c0 <syscalls+0x3a0>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	55e50513          	addi	a0,a0,1374 # 800088e0 <syscalls+0x3c0>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	56e50513          	addi	a0,a0,1390 # 80008900 <syscalls+0x3e0>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>

00000000800063a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063a2:	7119                	addi	sp,sp,-128
    800063a4:	fc86                	sd	ra,120(sp)
    800063a6:	f8a2                	sd	s0,112(sp)
    800063a8:	f4a6                	sd	s1,104(sp)
    800063aa:	f0ca                	sd	s2,96(sp)
    800063ac:	ecce                	sd	s3,88(sp)
    800063ae:	e8d2                	sd	s4,80(sp)
    800063b0:	e4d6                	sd	s5,72(sp)
    800063b2:	e0da                	sd	s6,64(sp)
    800063b4:	fc5e                	sd	s7,56(sp)
    800063b6:	f862                	sd	s8,48(sp)
    800063b8:	f466                	sd	s9,40(sp)
    800063ba:	f06a                	sd	s10,32(sp)
    800063bc:	ec6e                	sd	s11,24(sp)
    800063be:	0100                	addi	s0,sp,128
    800063c0:	8aaa                	mv	s5,a0
    800063c2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063c4:	00c52d03          	lw	s10,12(a0)
    800063c8:	001d1d1b          	slliw	s10,s10,0x1
    800063cc:	1d02                	slli	s10,s10,0x20
    800063ce:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063d2:	0001c517          	auipc	a0,0x1c
    800063d6:	cb650513          	addi	a0,a0,-842 # 80022088 <disk+0x128>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	7fc080e7          	jalr	2044(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800063e2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063e6:	0001cb97          	auipc	s7,0x1c
    800063ea:	b7ab8b93          	addi	s7,s7,-1158 # 80021f60 <disk>
  for(int i = 0; i < 3; i++){
    800063ee:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063f0:	0001cc97          	auipc	s9,0x1c
    800063f4:	c98c8c93          	addi	s9,s9,-872 # 80022088 <disk+0x128>
    800063f8:	a08d                	j	8000645a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063fa:	00fb8733          	add	a4,s7,a5
    800063fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006402:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006404:	0207c563          	bltz	a5,8000642e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006408:	2905                	addiw	s2,s2,1
    8000640a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000640c:	05690c63          	beq	s2,s6,80006464 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006410:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006412:	0001c717          	auipc	a4,0x1c
    80006416:	b4e70713          	addi	a4,a4,-1202 # 80021f60 <disk>
    8000641a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000641c:	01874683          	lbu	a3,24(a4)
    80006420:	fee9                	bnez	a3,800063fa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006422:	2785                	addiw	a5,a5,1
    80006424:	0705                	addi	a4,a4,1
    80006426:	fe979be3          	bne	a5,s1,8000641c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000642a:	57fd                	li	a5,-1
    8000642c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000642e:	01205d63          	blez	s2,80006448 <virtio_disk_rw+0xa6>
    80006432:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006434:	000a2503          	lw	a0,0(s4)
    80006438:	00000097          	auipc	ra,0x0
    8000643c:	cfe080e7          	jalr	-770(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    80006440:	2d85                	addiw	s11,s11,1
    80006442:	0a11                	addi	s4,s4,4
    80006444:	ff2d98e3          	bne	s11,s2,80006434 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006448:	85e6                	mv	a1,s9
    8000644a:	0001c517          	auipc	a0,0x1c
    8000644e:	b2e50513          	addi	a0,a0,-1234 # 80021f78 <disk+0x18>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	ee0080e7          	jalr	-288(ra) # 80002332 <sleep>
  for(int i = 0; i < 3; i++){
    8000645a:	f8040a13          	addi	s4,s0,-128
{
    8000645e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006460:	894e                	mv	s2,s3
    80006462:	b77d                	j	80006410 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006464:	f8042503          	lw	a0,-128(s0)
    80006468:	00a50713          	addi	a4,a0,10
    8000646c:	0712                	slli	a4,a4,0x4

  if(write)
    8000646e:	0001c797          	auipc	a5,0x1c
    80006472:	af278793          	addi	a5,a5,-1294 # 80021f60 <disk>
    80006476:	00e786b3          	add	a3,a5,a4
    8000647a:	01803633          	snez	a2,s8
    8000647e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006480:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006484:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006488:	f6070613          	addi	a2,a4,-160
    8000648c:	6394                	ld	a3,0(a5)
    8000648e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006490:	00870593          	addi	a1,a4,8
    80006494:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006496:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006498:	0007b803          	ld	a6,0(a5)
    8000649c:	9642                	add	a2,a2,a6
    8000649e:	46c1                	li	a3,16
    800064a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064a2:	4585                	li	a1,1
    800064a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064a8:	f8442683          	lw	a3,-124(s0)
    800064ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064b0:	0692                	slli	a3,a3,0x4
    800064b2:	9836                	add	a6,a6,a3
    800064b4:	058a8613          	addi	a2,s5,88
    800064b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064bc:	0007b803          	ld	a6,0(a5)
    800064c0:	96c2                	add	a3,a3,a6
    800064c2:	40000613          	li	a2,1024
    800064c6:	c690                	sw	a2,8(a3)
  if(write)
    800064c8:	001c3613          	seqz	a2,s8
    800064cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064d0:	00166613          	ori	a2,a2,1
    800064d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064d8:	f8842603          	lw	a2,-120(s0)
    800064dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064e0:	00250693          	addi	a3,a0,2
    800064e4:	0692                	slli	a3,a3,0x4
    800064e6:	96be                	add	a3,a3,a5
    800064e8:	58fd                	li	a7,-1
    800064ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064ee:	0612                	slli	a2,a2,0x4
    800064f0:	9832                	add	a6,a6,a2
    800064f2:	f9070713          	addi	a4,a4,-112
    800064f6:	973e                	add	a4,a4,a5
    800064f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800064fc:	6398                	ld	a4,0(a5)
    800064fe:	9732                	add	a4,a4,a2
    80006500:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006502:	4609                	li	a2,2
    80006504:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006508:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000650c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006510:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006514:	6794                	ld	a3,8(a5)
    80006516:	0026d703          	lhu	a4,2(a3)
    8000651a:	8b1d                	andi	a4,a4,7
    8000651c:	0706                	slli	a4,a4,0x1
    8000651e:	96ba                	add	a3,a3,a4
    80006520:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006524:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006528:	6798                	ld	a4,8(a5)
    8000652a:	00275783          	lhu	a5,2(a4)
    8000652e:	2785                	addiw	a5,a5,1
    80006530:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006534:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006538:	100017b7          	lui	a5,0x10001
    8000653c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006540:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006544:	0001c917          	auipc	s2,0x1c
    80006548:	b4490913          	addi	s2,s2,-1212 # 80022088 <disk+0x128>
  while(b->disk == 1) {
    8000654c:	4485                	li	s1,1
    8000654e:	00b79c63          	bne	a5,a1,80006566 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006552:	85ca                	mv	a1,s2
    80006554:	8556                	mv	a0,s5
    80006556:	ffffc097          	auipc	ra,0xffffc
    8000655a:	ddc080e7          	jalr	-548(ra) # 80002332 <sleep>
  while(b->disk == 1) {
    8000655e:	004aa783          	lw	a5,4(s5)
    80006562:	fe9788e3          	beq	a5,s1,80006552 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006566:	f8042903          	lw	s2,-128(s0)
    8000656a:	00290713          	addi	a4,s2,2
    8000656e:	0712                	slli	a4,a4,0x4
    80006570:	0001c797          	auipc	a5,0x1c
    80006574:	9f078793          	addi	a5,a5,-1552 # 80021f60 <disk>
    80006578:	97ba                	add	a5,a5,a4
    8000657a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000657e:	0001c997          	auipc	s3,0x1c
    80006582:	9e298993          	addi	s3,s3,-1566 # 80021f60 <disk>
    80006586:	00491713          	slli	a4,s2,0x4
    8000658a:	0009b783          	ld	a5,0(s3)
    8000658e:	97ba                	add	a5,a5,a4
    80006590:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006594:	854a                	mv	a0,s2
    80006596:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000659a:	00000097          	auipc	ra,0x0
    8000659e:	b9c080e7          	jalr	-1124(ra) # 80006136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065a2:	8885                	andi	s1,s1,1
    800065a4:	f0ed                	bnez	s1,80006586 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065a6:	0001c517          	auipc	a0,0x1c
    800065aa:	ae250513          	addi	a0,a0,-1310 # 80022088 <disk+0x128>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	6dc080e7          	jalr	1756(ra) # 80000c8a <release>
}
    800065b6:	70e6                	ld	ra,120(sp)
    800065b8:	7446                	ld	s0,112(sp)
    800065ba:	74a6                	ld	s1,104(sp)
    800065bc:	7906                	ld	s2,96(sp)
    800065be:	69e6                	ld	s3,88(sp)
    800065c0:	6a46                	ld	s4,80(sp)
    800065c2:	6aa6                	ld	s5,72(sp)
    800065c4:	6b06                	ld	s6,64(sp)
    800065c6:	7be2                	ld	s7,56(sp)
    800065c8:	7c42                	ld	s8,48(sp)
    800065ca:	7ca2                	ld	s9,40(sp)
    800065cc:	7d02                	ld	s10,32(sp)
    800065ce:	6de2                	ld	s11,24(sp)
    800065d0:	6109                	addi	sp,sp,128
    800065d2:	8082                	ret

00000000800065d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065d4:	1101                	addi	sp,sp,-32
    800065d6:	ec06                	sd	ra,24(sp)
    800065d8:	e822                	sd	s0,16(sp)
    800065da:	e426                	sd	s1,8(sp)
    800065dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065de:	0001c497          	auipc	s1,0x1c
    800065e2:	98248493          	addi	s1,s1,-1662 # 80021f60 <disk>
    800065e6:	0001c517          	auipc	a0,0x1c
    800065ea:	aa250513          	addi	a0,a0,-1374 # 80022088 <disk+0x128>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	5e8080e7          	jalr	1512(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065f6:	10001737          	lui	a4,0x10001
    800065fa:	533c                	lw	a5,96(a4)
    800065fc:	8b8d                	andi	a5,a5,3
    800065fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006600:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006604:	689c                	ld	a5,16(s1)
    80006606:	0204d703          	lhu	a4,32(s1)
    8000660a:	0027d783          	lhu	a5,2(a5)
    8000660e:	04f70863          	beq	a4,a5,8000665e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006612:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006616:	6898                	ld	a4,16(s1)
    80006618:	0204d783          	lhu	a5,32(s1)
    8000661c:	8b9d                	andi	a5,a5,7
    8000661e:	078e                	slli	a5,a5,0x3
    80006620:	97ba                	add	a5,a5,a4
    80006622:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006624:	00278713          	addi	a4,a5,2
    80006628:	0712                	slli	a4,a4,0x4
    8000662a:	9726                	add	a4,a4,s1
    8000662c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006630:	e721                	bnez	a4,80006678 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006632:	0789                	addi	a5,a5,2
    80006634:	0792                	slli	a5,a5,0x4
    80006636:	97a6                	add	a5,a5,s1
    80006638:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000663a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000663e:	ffffc097          	auipc	ra,0xffffc
    80006642:	d58080e7          	jalr	-680(ra) # 80002396 <wakeup>

    disk.used_idx += 1;
    80006646:	0204d783          	lhu	a5,32(s1)
    8000664a:	2785                	addiw	a5,a5,1
    8000664c:	17c2                	slli	a5,a5,0x30
    8000664e:	93c1                	srli	a5,a5,0x30
    80006650:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006654:	6898                	ld	a4,16(s1)
    80006656:	00275703          	lhu	a4,2(a4)
    8000665a:	faf71ce3          	bne	a4,a5,80006612 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000665e:	0001c517          	auipc	a0,0x1c
    80006662:	a2a50513          	addi	a0,a0,-1494 # 80022088 <disk+0x128>
    80006666:	ffffa097          	auipc	ra,0xffffa
    8000666a:	624080e7          	jalr	1572(ra) # 80000c8a <release>
}
    8000666e:	60e2                	ld	ra,24(sp)
    80006670:	6442                	ld	s0,16(sp)
    80006672:	64a2                	ld	s1,8(sp)
    80006674:	6105                	addi	sp,sp,32
    80006676:	8082                	ret
      panic("virtio_disk_intr status");
    80006678:	00002517          	auipc	a0,0x2
    8000667c:	2a050513          	addi	a0,a0,672 # 80008918 <syscalls+0x3f8>
    80006680:	ffffa097          	auipc	ra,0xffffa
    80006684:	ec0080e7          	jalr	-320(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

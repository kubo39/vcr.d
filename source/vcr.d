/**
 *  Valgrind client request for D.
 *    ref: http://valgrind.org/docs/manual/manual-core-adv.html#manual-core-adv.clientreq
 */
module vcr;


private int vg_userreq_tool_base(char a, char b) pure @nogc
{
    return (a & 0xff) << 24 | (b & 0xff) << 16;
}


/// from valgrind/valgrind.h.
enum Vg_ClientRequest
{
    RUNNING_ON_VALGRIND  = 0x1001,
    DISCARD_TRANSLATIONS = 0x1002,

    /* These allow any function to be called from the simulated
       CPU but run on the real CPU.  Nb: the first arg passed to
       the function is always the ThreadId of the running
       thread!  So CLIENT_CALL0 actually requires a 1 arg
       function, etc. */
    CLIENT_CALL0 = 0x1101,
    CLIENT_CALL1 = 0x1102,
    CLIENT_CALL2 = 0x1103,
    CLIENT_CALL3 = 0x1104,

    /* Can be useful in regression testing suites -- eg. can
       send Valgrind's output to /dev/null and still count
       errors. */
    COUNT_ERRORS = 0x1201,

    /* Allows the client program and/or gdbserver to execute a monitor
       command. */
    GDB_MONITOR_COMMAND = 0x1202,

    /* These are useful and can be interpreted by any tool that
       tracks malloc() et al, by using vg_replace_malloc.c. */
    MALLOCLIKE_BLOCK = 0x1301,
    RESIZEINPLACE_BLOCK = 0x130b,
    FREELIKE_BLOCK   = 0x1302,
    /* Memory pool support. */
    CREATE_MEMPOOL   = 0x1303,
    DESTROY_MEMPOOL  = 0x1304,
    MEMPOOL_ALLOC    = 0x1305,
    MEMPOOL_FREE     = 0x1306,
    MEMPOOL_TRIM     = 0x1307,
    MOVE_MEMPOOL     = 0x1308,
    MEMPOOL_CHANGE   = 0x1309,
    MEMPOOL_EXISTS   = 0x130a,

    /* Allow printfs to valgrind log. */
    /* The first two pass the va_list argument by value, which
       assumes it is the same size as or smaller than a UWord,
       which generally isn't the case.  Hence are deprecated.
       The second two pass the vargs by reference and so are
       immune to this problem. */
    /* both :: char* fmt, va_list vargs (DEPRECATED) */
    PRINTF           = 0x1401,
    PRINTF_BACKTRACE = 0x1402,
    /* both :: char* fmt, va_list* vargs */
    PRINTF_VALIST_BY_REF = 0x1403,
    PRINTF_BACKTRACE_VALIST_BY_REF = 0x1404,

    /* Stack support. */
    STACK_REGISTER   = 0x1501,
    STACK_DEREGISTER = 0x1502,
    STACK_CHANGE     = 0x1503,

    /* Wine support */
    LOAD_PDB_DEBUGINFO = 0x1601,

    /* Querying of debug info. */
    MAP_IP_TO_SRCLOC = 0x1701,

    /* Disable/enable error reporting level.  Takes a single
       Word arg which is the delta to this thread's error
       disablement indicator.  Hence 1 disables or further
       disables errors, and -1 moves back towards enablement.
       Other values are not allowed. */
    CHANGE_ERR_DISABLEMENT = 0x1801,

    /* Initialise IR injection */
    VEX_INIT_FOR_IRI = 0x1901
}


//from valgrind/callgrind.h
enum Vg_CallgrindClientRequest
{
    DUMP_STATS = vg_userreq_tool_base('C','T'),
    ZERO_STATS,
    TOGGLE_COLLECT,
    DUMP_STATS_AT,
    START_INSTRUMENTATION,
    STOP_INSTRUMENTATION
}


// from valgrind/memcheck.h
enum Vg_MemCheckClientRequest
{
    MAKE_MEM_NOACCESS = vg_userreq_tool_base('M','C'),
    MAKE_MEM_UNDEFINED,
    MAKE_MEM_DEFINED,
    DISCARD,
    CHECK_MEM_IS_ADDRESSABLE,
    CHECK_MEM_IS_DEFINED,
    DO_LEAK_CHECK,
    COUNT_LEAKS,
    GET_VBITS,
    SET_VBITS,
    CREATE_BLOCK,
    MAKE_MEM_DEFINED_IF_ADDRESSABLE,

    /* Not next to VG_USERREQ__COUNT_LEAKS because it was added later. */
    COUNT_LEAK_BLOCKS,

    ENABLE_ADDR_ERROR_REPORTING_IN_RANGE,
    DISABLE_ADDR_ERROR_REPORTING_IN_RANGE,

    /* This is just for memcheck's internal use - don't use it */
    _MEMCHECK_RECORD_OVERLAP_ERROR = vg_userreq_tool_base('M','C') + 256
}


// from valgrind/helgrind.h
enum Vg_TCheckClientRequest
{
    HG_CLEAN_MEMORY = vg_userreq_tool_base('H','G')
}


// from valgrind/drd.h
enum Vg_DRDClientRequest
{
   /* Ask the DRD tool to discard all information about memory accesses   */
   /* and client objects for the specified range. This client request is  */
   /* binary compatible with the similarly named Helgrind client request. */
   DRD_CLEAN_MEMORY = vg_userreq_tool_base('H','G'),
   /* args: Addr, SizeT. */

   /* Ask the DRD tool the thread ID assigned by Valgrind. */
   DRD_GET_VALGRIND_THREAD_ID = vg_userreq_tool_base('D','R'),
   /* args: none. */
   /* Ask the DRD tool the thread ID assigned by DRD. */
   DRD_GET_DRD_THREAD_ID,
   /* args: none. */

   /* To tell the DRD tool to suppress data race detection on the */
   /* specified address range. */
   DRD_START_SUPPRESSION,
   /* args: start address, size in bytes */
   /* To tell the DRD tool no longer to suppress data race detection on */
   /* the specified address range. */
   DRD_FINISH_SUPPRESSION,
   /* args: start address, size in bytes */

   /* To ask the DRD tool to trace all accesses to the specified range. */
   DRD_START_TRACE_ADDR,
   /* args: Addr, SizeT. */
   /* To ask the DRD tool to stop tracing accesses to the specified range. */
   DRD_STOP_TRACE_ADDR,
   /* args: Addr, SizeT. */

   /* Tell DRD whether or not to record memory loads in the calling thread. */
   DRD_RECORD_LOADS,
   /* args: Bool. */
   /* Tell DRD whether or not to record memory stores in the calling thread. */
   DRD_RECORD_STORES,
   /* args: Bool. */

   /* Set the name of the thread that performs this client request. */
   DRD_SET_THREAD_NAME,
   /* args: null-terminated character string. */
}


version(D_InlineAsm_X86_64)
{
    size_t doClientRequest(size_t flag, ref size_t[6] args)
    {
        size_t result = void;
        asm
        {
            mov RDX, flag[RBP];
            mov RAX, args;
            rol RDI, 0x3;
            rol RDI, 0xd;
            rol RDI, 0x3d;
            rol RDI, 0x33;
            xchg RBX, RBX;
            mov result, RDX;
        }
        return result;
    }
}
else version(D_InlineAsm_X86)
{
    size_t doClientRequest(size_t flag, ref size_t[6] args)
    {
        size_t result = void;
        asm
        {
            mov EAX, args[EBP];
            mov EDX, flag;
            rol EDI, 0x3;
            rol EDI, 0xd;
            rol EDI, 0x1d;
            rol EDI, 0x13;
            xchg EBX, EBX;
            mov result, EDX;
        }
        return result;
    }
}
else static assert(false, "Unsupported arch.");



/**
 *  Client requests for valgrind core.
 */

size_t runningOnValgrind()
{
    size_t[6] arr = [Vg_ClientRequest.RUNNING_ON_VALGRIND, 0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t countErrors()
{
    size_t[6] arr = [Vg_ClientRequest.COUNT_ERRORS, 0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t stackRegister(const void* start, const void* end)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_REGISTER,
                     cast(size_t) start,
                     cast(size_t) end,
                     0, 0, 0];
    return doClientRequest(0, arr);
}


size_t stackChange(size_t id, const void* start, const void* end)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_CHANGE,
                     id,
                     cast(size_t) start,
                     cast(size_t) end,
                     0, 0];
    return doClientRequest(0, arr);
}


void stackDeregister(size_t id)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_DEREGISTER,
                     id,
                     0, 0, 0, 0];
    doClientRequest(0, arr);
}


size_t discardTranslation(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_ClientRequest.DISCARD_TRANSLATIONS,
                     cast(size_t) addr, len,
                     0, 0, 0];
    return doClientRequest(0, arr);
}


/**
 *  Client requests for callgrind.
 */
size_t dumpStats()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.DUMP_STATS,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t dumpStatsAt(const void* posStr)
{
    size_t[6] arr = [Vg_CallgrindClientRequest.DUMP_STATS_AT,
                     cast(size_t) posStr, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t zeroStats()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.ZERO_STATS,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t toggleCollect()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.TOGGLE_COLLECT,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t startInstrumentation()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.START_INSTRUMENTATION,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t stopInstrumentation()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.STOP_INSTRUMENTATION,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/**
 *  Client requests for memcheck.
 */

size_t makeMemNoaccess(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_NOACCESS,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t makeMemUndefined(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_UNDEFINED,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t makeMemDefined(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_DEFINED,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t makeMemDefinedIfAddressable(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_DEFINED_IF_ADDRESSABLE,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t doLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t doAddedLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 1, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t doChangedLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 2, 0, 0, 0];
    return doClientRequest(0, arr);
}


size_t doQuicLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     1, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


private struct LeakCount
{
    size_t leaked;
    size_t dubious;
    size_t reachable;
    size_t suppressed;
}


LeakCount countLeaks()
{
    auto counts = LeakCount(0, 0, 0, 0);
    size_t[6] arr = [Vg_MemCheckClientRequest.COUNT_LEAKS,
                     cast(size_t) &counts.leaked,
                     cast(size_t) &counts.dubious,
                     cast(size_t) &counts.reachable,
                     cast(size_t) &counts.suppressed,
                     0];
    doClientRequest(0, arr);
    return counts;
}


LeakCount countLeakBlocks()
{
    auto counts = LeakCount(0, 0, 0, 0);
    size_t[6] arr = [Vg_MemCheckClientRequest.COUNT_LEAK_BLOCKS,
                     cast(size_t) &counts.leaked,
                     cast(size_t) &counts.dubious,
                     cast(size_t) &counts.reachable,
                     cast(size_t) &counts.suppressed,
                     0];
    doClientRequest(0, arr);
    return counts;
}


unittest
{
    assert(runningOnValgrind() == 1);
}

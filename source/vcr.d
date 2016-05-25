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

/* Returns the number of Valgrinds this code is running under.  That
   is, 0 if running natively, 1 if running under Valgrind, 2 if
   running under Valgrind which is running under another Valgrind,
   etc. */
size_t runningOnValgrind()
{
    size_t[6] arr = [Vg_ClientRequest.RUNNING_ON_VALGRIND, 0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Discard translation of code in the range [addr .. addr +
   len - 1].  Useful if you are debugging a JITter or some such,
   since it provides a way to make sure valgrind will retranslate the
   invalidated area.  Returns no value. */
void discardTranslation(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_ClientRequest.DISCARD_TRANSLATIONS,
                     cast(size_t) addr, len,
                     0, 0, 0];
    doClientRequest(0, arr);
}


/* Counts the number of errors that have been recorded by a tool. */
size_t countErrors()
{
    size_t[6] arr = [Vg_ClientRequest.COUNT_ERRORS, 0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Mark a piece of memory as being a stack. Returns a stack id.
   start is the lowest addressable stack byte, end is the highest
   addressable stack byte. */
size_t stackRegister(const void* start, const void* end)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_REGISTER,
                     cast(size_t) start,
                     cast(size_t) end,
                     0, 0, 0];
    return doClientRequest(0, arr);
}


/* Change the start and end address of the stack id.
   start is the new lowest addressable stack byte, end is the new highest
   addressable stack byte. */
size_t stackChange(size_t id, const void* start, const void* end)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_CHANGE,
                     id,
                     cast(size_t) start,
                     cast(size_t) end,
                     0, 0];
    return doClientRequest(0, arr);
}


/* Unmark the piece of memory associated with a stack id as being a
   stack. */
void stackDeregister(size_t id)
{
    size_t[6] arr = [Vg_ClientRequest.STACK_DEREGISTER,
                     id,
                     0, 0, 0, 0];
    doClientRequest(0, arr);
}


/**
 *  Client requests for callgrind.
 */

/* Dump current state of cost centers, and zero them afterwards */
size_t dumpStats()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.DUMP_STATS,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Dump current state of cost centers, and zero them afterwards.
   The argument is appended to a string stating the reason which triggered
   the dump. This string is written as a description field into the
   profile data dump. */
size_t dumpStatsAt(const void* posStr)
{
    size_t[6] arr = [Vg_CallgrindClientRequest.DUMP_STATS_AT,
                     cast(size_t) posStr, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Zero cost centers */
size_t zeroStats()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.ZERO_STATS,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Toggles collection state.
   The collection state specifies whether the happening of events
   should be noted or if they are to be ignored. Events are noted
   by increment of counters in a cost center */
size_t toggleCollect()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.TOGGLE_COLLECT,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Start full callgrind instrumentation if not already switched on.
   When cache simulation is done, it will flush the simulated cache;
   this will lead to an artifical cache warmup phase afterwards with
   cache misses which would not have happened in reality. */
size_t startInstrumentation()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.START_INSTRUMENTATION,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Stop full callgrind instrumentation if not already switched off.
   This flushes Valgrinds translation cache, and does no additional
   instrumentation afterwards, which effectivly will run at the same
   speed as the "none" tool (ie. at minimal slowdown).
   Use this to bypass Callgrind aggregation for uninteresting code parts.
   To start Callgrind in this mode to ignore the setup phase, use
   the option "--instr-atstart=no". */
size_t stopInstrumentation()
{
    size_t[6] arr = [Vg_CallgrindClientRequest.STOP_INSTRUMENTATION,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/**
 *  Client requests for memcheck.
 */

/* Mark memory at addr as unaddressable for len bytes. */
size_t makeMemNoaccess(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_NOACCESS,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Similarly, mark memory at addr as addressable but undefined
   for len bytes. */
size_t makeMemUndefined(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_UNDEFINED,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Similarly, mark memory at addr as addressable and defined
   for len bytes. */
size_t makeMemDefined(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_DEFINED,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Similar to VALGRIND_MAKE_MEM_DEFINED except that addressability is
   not altered: bytes which are addressable are marked as defined,
   but those which are not addressable are left unchanged. */
size_t makeMemDefinedIfAddressable(const void* addr, size_t len)
{
    size_t[6] arr = [Vg_MemCheckClientRequest.MAKE_MEM_DEFINED_IF_ADDRESSABLE,
                     cast(size_t) addr, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Do a full memory leak check (like --leak-check=full) mid-execution. */
size_t doLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Same as VALGRIND_DO_LEAK_CHECK but only showing the entries for
   which there was an increase in leaked bytes or leaked nr of blocks
   since the previous leak search. */
size_t doAddedLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 1, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Same as VALGRIND_DO_ADDED_LEAK_CHECK but showing entries with
   increased or decreased leaked bytes/blocks since previous leak
   search. */
size_t doChangedLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     0, 2, 0, 0, 0];
    return doClientRequest(0, arr);
}


/* Do a summary memory leak check (like --leak-check=summary) mid-execution. */
size_t doQuicLeakCheck()
{
    size_t[6] arr = [Vg_MemCheckClientRequest.DO_LEAK_CHECK,
                     1, 0, 0, 0, 0];
    return doClientRequest(0, arr);
}


struct LeakCount
{
    size_t leaked;
    size_t dubious;
    size_t reachable;
    size_t suppressed;
}


/* Return number of leaked, dubious, reachable and suppressed bytes found by
   all previous leak checks.  They must be lvalues.  */
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


/* Return number of leaked, dubious, reachable and suppressed bytes found by
   all previous leak checks.  They must be lvalues.  */
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


/**
 *  Client requests for helgrind.
 */


/* Clean memory state.  This makes Helgrind forget everything it knew
   about the specified memory range.  Effectively this announces that
   the specified memory range now "belongs" to the calling thread, so
   that: (1) the calling thread can access it safely without
   synchronisation, and (2) all other threads must sync with this one
   to access it safely.  This is particularly useful for memory
   allocators that wish to recycle memory. */
size_t cleanMemory(const void* start, size_t len)
{
    size_t[6] arr = [Vg_TCheckClientRequest.HG_CLEAN_MEMORY,
                     cast(size_t) start, len, 0, 0, 0];
    return doClientRequest(0, arr);
}


unittest
{
    assert(runningOnValgrind() == 1);
}

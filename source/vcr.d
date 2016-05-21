module vcr;


enum VG_USERREQ
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


version(D_InlineAsm_X86_64)
{
    ulong valgrindClientRequest(ulong flag, uint[6] args)
    {
        ulong result= void;
        auto _args = args.dup.ptr;
        asm
        {
            mov RDX, flag[RBP];
            mov RAX, _args;
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
else static assert(false, "Unsupported arch.");



ulong running_on_valgrind()
{
    return valgrindClientRequest(0, [VG_USERREQ.RUNNING_ON_VALGRIND, 0, 0, 0, 0, 0]);
}


unittest
{
    assert(running_on_valgrind() == 1);
}

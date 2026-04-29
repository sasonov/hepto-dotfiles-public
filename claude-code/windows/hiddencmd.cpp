// hiddencmd.cpp — GUI-subsystem cmd.exe wrapper
//
// This is the KEY workaround for the Claude Code Windows console flashing bug.
//
// Problem: Claude Code spawns child processes without CREATE_NO_WINDOW,
// causing visible PowerShell/conhost.exe windows to flash on screen.
// Node.js's windowsHide:true doesn't help because cmd.exe creates conhost.exe
// during its own initialization BEFORE any creation flags take effect.
//
// Solution: This wrapper is compiled as a Windows GUI subsystem binary,
// which prevents Windows from allocating a console for it. It then spawns
// the REAL cmd.exe with CREATE_NO_WINDOW (0x08000000) to suppress child
// console windows as well.
//
// CRITICAL: This MUST be named "cmd.exe" — Node.js uses a regex
// /^(?:.*\\)?cmd(?:\.exe)?$/i to detect cmd.exe and adjust its quoting
// behavior. If named anything else, Node.js will use POSIX quoting rules
// which break cmd.exe's /d /s /c handling.
//
// Build (MinGW-w64 or MSVC):
//   MinGW:  g++ -O2 -municode -Wl,-subsystem,windows -o hiddencmd.exe hiddencmd.cpp -lshell32
//   MSVC:   cl /O2 /DJ UNICODE /SUBSYSTEM:WINDOWS hiddencmd.cpp shell32.lib
//
// Install: Copy hiddencmd.exe to %USERPROFILE%\.claude\windows\cmd.exe
//          (renamed from hiddencmd.exe to cmd.exe)
//
// Usage: Set COMSPEC=%USERPROFILE%\.claude\windows\cmd.exe before launching claude.

#include <windows.h>
#include <string.h>
#include <stdio.h>
#include <string>

int wWinMain(HINSTANCE hInst, HINSTANCE hPrev, LPWSTR cmdLine, int nShow) {
    // Path to the real cmd.exe
    wchar_t realCmd[MAX_PATH];
    GetSystemDirectoryW(realCmd, MAX_PATH);
    wcscat_s(realCmd, MAX_PATH, L"\\cmd.exe");

    // Build command line: real cmd.exe with whatever args were passed
    // + CREATE_NO_WINDOW to suppress child console windows
    std::wstring args;

    // Get the full original command line
    LPWSTR origCmdLine = GetCommandLineW();

    // Skip our own executable name in the command line
    // The original command line contains: "path\to\hiddencmd.exe" /d /s /c "actual command"
    // We want to pass everything after our exe name to real cmd.exe

    BOOL quoteStarted = FALSE;
    int i = 0;

    // Skip leading whitespace
    while (origCmdLine[i] == L' ' || origCmdLine[i] == L'\t') i++;

    // Skip our executable name (quoted or unquoted)
    if (origCmdLine[i] == L'"') {
        i++; // skip opening quote
        while (origCmdLine[i] && origCmdLine[i] != L'"') i++;
        if (origCmdLine[i] == L'"') i++; // skip closing quote
    } else {
        while (origCmdLine[i] && origCmdLine[i] != L' ' && origCmdLine[i] != L'\t') i++;
    }

    // Skip whitespace after exe name
    while (origCmdLine[i] == L' ' || origCmdLine[i] == L'\t') i++;

    // The remaining string is the arguments for real cmd.exe
    args = origCmdLine + i;

    // Build full command: realCmd.exe <args>
    std::wstring fullCmdLine = L"\"";
    fullCmdLine += realCmd;
    fullCmdLine += L"\" ";
    fullCmdLine += args;

    STARTUPINFOW si = {0};
    si.cb = sizeof(si);
    // Forward Node.js's stdio pipes to real cmd.exe, otherwise child output is lost.
    si.dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
    si.wShowWindow = SW_HIDE;
    si.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
    si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    si.hStdError  = GetStdHandle(STD_ERROR_HANDLE);

    PROCESS_INFORMATION pi = {0};

    // CREATE_NO_WINDOW = 0x08000000 — prevents conhost.exe allocation
    DWORD creationFlags = CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT;

    // Create the process with stdio inherited from parent
    BOOL success = CreateProcessW(
        realCmd,                     // executable
        &fullCmdLine[0],            // command line (mutable)
        NULL,                        // process security
        NULL,                        // thread security
        TRUE,                        // inherit handles (for stdio)
        creationFlags,               // creation flags
        NULL,                        // environment
        NULL,                        // current directory
        &si,                         // startup info
        &pi                          // process info
    );

    if (!success) {
        // If we can't create the process, try without CREATE_NO_WINDOW
        // (fallback for edge cases)
        creationFlags = CREATE_UNICODE_ENVIRONMENT;

        success = CreateProcessW(
            realCmd, &fullCmdLine[0],
            NULL, NULL, TRUE, creationFlags,
            NULL, NULL, &si, &pi
        );

        if (!success) {
            return 1;
        }
    }

    // Wait for the child process to complete
    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exitCode = 1;
    GetExitCodeProcess(pi.hProcess, &exitCode);

    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return (int)exitCode;
}
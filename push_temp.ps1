$Target = "GitHub - https://api.github.com/XxvoltikxX"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class CredManager {
    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }
    public static string GetSecret(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            var cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, cred.CredentialBlobSize);
            return System.Text.Encoding.Unicode.GetString(bytes);
        }
        return null;
    }
}
"@

$token = [CredManager]::GetSecret($Target)
if ($token) {
    git add -A
    git commit -m "feat(ui): ultra-sleek bento settings redesign for modules, sliders, toggles and settings tab"
    git push https://XxvoltikxX:$token@github.com/XxvoltikxX/MenuTest.git main
    Write-Host "PUSH_SUCCESSFUL"
} else {
    Write-Error "Could not read token from Credential Manager"
}

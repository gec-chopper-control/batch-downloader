VERSION 5.00
Begin VB.Form frmBatchAdd 
   Caption         =   "일괄 다운로드"
   ClientHeight    =   3795
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   5985
   BeginProperty Font 
      Name            =   "굴림"
      Size            =   9
      Charset         =   129
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "frmBatchAdd.frx":0000
   LinkTopic       =   "Form1"
   MinButton       =   0   'False
   ScaleHeight     =   3795
   ScaleWidth      =   5985
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  '소유자 가운데
   Begin prjDownloadBooster.CommandButtonW cmdAdvanced 
      Height          =   340
      Left            =   4560
      TabIndex        =   7
      Top             =   900
      Width           =   1335
      _ExtentX        =   2355
      _ExtentY        =   609
      Caption         =   "고급(&V)..."
   End
   Begin VB.TextBox txtSavePath 
      Height          =   255
      Left            =   120
      TabIndex        =   3
      Top             =   3405
      Width           =   4215
   End
   Begin VB.TextBox txtURLs 
      Height          =   2535
      Left            =   120
      MultiLine       =   -1  'True
      ScrollBars      =   3  '양방향
      TabIndex        =   1
      Top             =   360
      Width           =   4215
   End
   Begin prjDownloadBooster.CommandButtonW cmdCancel 
      Cancel          =   -1  'True
      Height          =   340
      Left            =   4560
      TabIndex        =   6
      Top             =   510
      Width           =   1335
      _ExtentX        =   0
      _ExtentY        =   0
      Caption         =   "취소"
   End
   Begin prjDownloadBooster.CommandButtonW cmdOK 
      Height          =   340
      Left            =   4560
      TabIndex        =   5
      Top             =   120
      Width           =   1335
      _ExtentX        =   0
      _ExtentY        =   0
      Caption         =   "확인"
   End
   Begin prjDownloadBooster.CommandButtonW cmdBrowse 
      Height          =   330
      Left            =   4560
      TabIndex        =   4
      Top             =   3360
      Width           =   1335
      _ExtentX        =   2355
      _ExtentY        =   582
      Caption         =   "찾아보기(&B)..."
   End
   Begin VB.Label Label2 
      BackStyle       =   0  '투명
      Caption         =   "저장 경로(&S):"
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   3165
      Width           =   2775
   End
   Begin VB.Label Label1 
      BackStyle       =   0  '투명
      Caption         =   "각 줄에 파일 주소를 입력하십시오(&L)."
      Height          =   255
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   4215
   End
End
Attribute VB_Name = "frmBatchAdd"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'참고자료
'https://blog.naver.com/wnwlsrb3/220729779017
Dim PrevKeyCode As Integer
Dim Initialized As Boolean
Public HeaderCache$

Implements IBSSubclass

Private Sub cmdAdvanced_Click()
    Tags.DownloadOptionsTargetForm = 1
    Set frmDownloadOptions.HeaderKeys = New Collection
    Set frmDownloadOptions.Headers = New Collection
    frmDownloadOptions.Show vbModal, Me
End Sub

Private Sub cmdBrowse_Click()
    txtSavePath.Text = Trim$(txtSavePath.Text)
    
    Unload frmBrowse
    Unload frmExplorer
    Tags.BrowsePresetPath = txtSavePath.Text
    Tags.BrowseTargetForm = 2
    If GetSetting("DownloadBooster", "Options", "ForceWin31Dialog", "0") = "1" Then
        frmBrowse.Show vbModal, Me
    Else
        frmExplorer.Show vbModal, Me
    End If
End Sub

Private Sub cmdCancel_Click()
    Unload Me
End Sub

Private Sub cmdOK_Click()
    txtSavePath.Text = Trim$(txtSavePath.Text)
    If Not FolderExists(txtSavePath.Text) Then
        MsgBox t("저장 경로가 존재하지 않습니다. [찾아보기] 기능으로 폴더를 찾아볼 수 있습니다.", "Save path does not exist. Use Broewse to browse folders."), 16
        Exit Sub
    End If
    txtSavePath.Text = FilterFilename(txtSavePath.Text, True)

    Dim URLs() As String
    URLs = Split(txtURLs.Text, vbCrLf)
    Dim ErrURLs$
    ErrURLs = ""
    For i = 0 To UBound(URLs)
        If Replace(URLs(i), " ", "") <> "" Then
            If frmMain.AddBatchURLs(URLs(i), txtSavePath.Text, HeaderCache) = False Then
                ErrURLs = ErrURLs & URLs(i) & vbCrLf
            End If
        End If
    Next i
    
    If ErrURLs = "" Then
        Unload Me
    Else
        txtURLs.Text = ErrURLs
        txtURLs.SelStart = 0
        txtURLs.SelLength = Len(txtURLs.Text)
        On Error Resume Next
        txtURLs.SetFocus
    End If
End Sub

Private Sub Form_Activate()
    If Initialized Then Exit Sub
    Initialized = True
    
    txtURLs.SetFocus
End Sub

Private Sub Form_Load()
    InitForm Me
    Initialized = False
    
    Me.Caption = t(Me.Caption, "Batch download")
    cmdOK.Caption = t(cmdOK.Caption, "OK")
    cmdCancel.Caption = t(cmdCancel.Caption, "Cancel")
    Label1.Caption = t(Label1.Caption, "Enter one UR&L per line:")
    Label2.Caption = t(Label2.Caption, "&Save to:")
    cmdBrowse.Caption = t(cmdBrowse.Caption, "&Browse...")
    tr cmdAdvanced, "Ad&vanced..."
    
    HeaderCache = ""
    
    On Error Resume Next
    Me.Width = GetSetting("DownloadBooster", "UserData", "BatchURLAddWidth", Me.Width - PaddedBorderWidth * 15 * 2) + PaddedBorderWidth * 15 * 2
    Me.Height = GetSetting("DownloadBooster", "UserData", "BatchURLAddHeight", Me.Height - PaddedBorderWidth * 15 * 2) + PaddedBorderWidth * 15 * 2
    
    AttachMessage Me, Me.hWnd, WM_GETMINMAXINFO
    AttachMessage Me, Me.hWnd, WM_SETTINGCHANGE
End Sub

Sub Form_Resize()
    If Me.WindowState = 1 Then Exit Sub
    cmdOK.Left = Me.Width - PaddedBorderWidth * 15 * 2 - 1545
    cmdCancel.Left = cmdOK.Left
    cmdAdvanced.Left = cmdOK.Left
    txtURLs.Width = Me.Width - PaddedBorderWidth * 15 * 2 - 1890
    txtURLs.Height = Me.Height - PaddedBorderWidth * 15 * 2 - 1770
    Label2.Top = Me.Height - PaddedBorderWidth * 15 * 2 - 1140
    txtSavePath.Top = Me.Height - PaddedBorderWidth * 15 * 2 - 900
    cmdBrowse.Left = cmdOK.Left
    cmdBrowse.Top = Me.Height - PaddedBorderWidth * 15 * 2 - 945
    txtSavePath.Width = txtURLs.Width
End Sub

Private Sub Form_Unload(Cancel As Integer)
    If Me.WindowState = 0 Then
        SaveSetting "DownloadBooster", "UserData", "BatchURLAddWidth", Me.Width - PaddedBorderWidth * 15 * 2
        SaveSetting "DownloadBooster", "UserData", "BatchURLAddHeight", Me.Height - PaddedBorderWidth * 15 * 2
    End If
    
    IBSSubclass_UnsubclassIt
End Sub

Private Function IBSSubclass_MsgResponse(ByVal hWnd As Long, ByVal uMsg As Long) As EMsgResponse
    IBSSubclass_MsgResponse = emrConsume
End Function

Private Sub IBSSubclass_UnsubclassIt()
    DetachMessage Me, Me.hWnd, WM_GETMINMAXINFO
    DetachMessage Me, Me.hWnd, WM_SETTINGCHANGE
End Sub

Private Function IBSSubclass_WindowProc(ByVal hWnd As Long, ByVal uMsg As Long, ByRef wParam As Long, ByRef lParam As Long, ByRef bConsume As Boolean) As Long
    On Error Resume Next
 
    Select Case uMsg
        Case WM_GETMINMAXINFO
            Dim lpMMI As MINMAXINFO
            CopyMemory lpMMI, ByVal lParam, Len(lpMMI)
            lpMMI.ptMinTrackSize.X = (5145 + PaddedBorderWidth * 15 * 2) / 15 * (DPI / 96)
            lpMMI.ptMinTrackSize.Y = (2310 + PaddedBorderWidth * 15 * 2) / 15 * (DPI / 96)
            lpMMI.ptMaxTrackSize.X = (Screen.Width + 1200) * (DPI / 96)
            lpMMI.ptMaxTrackSize.Y = (Screen.Height + 1200) * (DPI / 96)
            CopyMemory ByVal lParam, lpMMI, Len(lpMMI)
            
            IBSSubclass_WindowProc = 1&
            Exit Function
        Case WM_SETTINGCHANGE
            Select Case GetStrFromPtr(lParam)
                Case "WindowMetrics"
                    UpdateBorderWidth
                    Form_Resize
            End Select
    End Select
    
    IBSSubclass_WindowProc = CallOldWindowProc(hWnd, uMsg, wParam, lParam)
End Function

Private Sub txtURLs_KeyDown(KeyCode As Integer, Shift As Integer)
    If (KeyCode = 13 Or KeyCode = 10) Then
        If (PrevKeyCode = 13 Or PrevKeyCode = 10) Then
            cmdOK_Click
        End If
        PrevKeyCode = KeyCode
    Else
        PrevKeyCode = 0
    End If
End Sub

Private Sub txtURLs_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    PrevKeyCode = 0
End Sub

codeunit 82003 "Parse Bank Transaction Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure FillTransactionTextFromDescription(var BankAccRecLine: record "Bank Acc. Reconciliation Line")
    var
        TransactionText: text;
    begin

        //BankAccRecLine.SetRange("Bank Account No.", BankAccNoCode);
        //BankAccRecLine.SetRange("Transaction Text", '');
        if BankAccRecLine.FindSet(true, false) then
            repeat
                TransactionText := SearchDocNo(BankAccRecLine);
                ConvertDescriptionsToTransactionText(BankAccRecLine."AVU Description 1", BankAccRecLine."AVU Description 2", BankAccRecLine."AVU Description 3", TransactionText);
                CheckTrapassoText(BankAccRecLine, TransactionText);
                if TransactionText = '' then
                    TransactionText := GetSpecialMapping(BankAccRecLine);


                if TransactionText <> '' then begin
                    BankAccRecLine.VALIDATE("Transaction Text", Copystr(TransactionText, 1, 140));
                    BankAccRecLine.Modify();
                end;
            until BankAccRecLine.next = 0;
    end;

    procedure UpdateTransactionText(pBankAccReconilLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconcilLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        Customer: Record Customer;
        VendCustomerPart: Text;
        DocNoPart: Text;
    begin
        BankAccReconcilLine.SetRange("Bank Account No.", pBankAccReconilLine."Bank Account No.");
        BankAccReconcilLine.SetRange("Statement Type", pBankAccReconilLine."Statement Type");
        BankAccReconcilLine.SetRange("Statement No.", pBankAccReconilLine."Statement No.");
        BankAccReconcilLine.SetFilter("Account Type", '%1|%2', BankAccReconcilLine."Account Type"::Customer, BankAccReconcilLine."Account Type"::Vendor);
        If BankAccReconcilLine.FindSet(true, false) then
            repeat
                VendCustomerPart := '';
                DocNoPart := '';
                DocNoPart := BankAccReconcilLine.GetAppliedToDocumentNo();

                If BankAccReconcilLine."Account Type" = BankAccReconcilLine."Account Type"::Vendor then
                    If Vendor.get(BankAccReconcilLine."Account No.") then
                        VendCustomerPart := Vendor.Name;

                If BankAccReconcilLine."Account Type" = BankAccReconcilLine."Account Type"::Customer then
                    If Customer.get(BankAccReconcilLine."Account No.") then
                        VendCustomerPart := Customer.Name;

                BankAccReconcilLine.VALIDATE("Transaction Text", CopyStr(VendCustomerPart + ' ' + DocNoPart, 1, MaxStrLen(BankAccReconcilLine."Transaction Text")));

                if DocNoPart <> '' then
                    BankAccReconcilLine.Modify();
            until BankAccReconcilLine.Next = 0;
        Message('Done');

    end;

    local procedure ConvertDescriptionsToTransactionText(Desc: text; Desc2: text; Desc3: text; var TransactionText: text)
    begin
        if (Desc <> '') and (desc = UpperCase(Desc)) then
            TransactionText += ' ' + desc;
        if (Desc2 <> '') and (desc2 = UpperCase(desc2)) then
            TransactionText += ' ' + desc2;
        if (Desc3 <> '') and (desc3 = UpperCase(Desc3)) then
            TransactionText += ' ' + desc3;
    end;

    local procedure GetSpecialMapping(BankAccRecLine: record "Bank Acc. Reconciliation Line") TransactionText: Text
    var
        desc1: Text;

    begin

        desc1 := UpperCase(BankAccRecLine."AVU Description 1");

        if StrPos(desc1, 'SALARIO') <> 0 then
            TransactionText := 'Div. ordini perm. salario';

        if StrPos(desc1, UpperCase('Saldo prezzi prestazioni')) <> 0 then begin
            TransactionText := 'Saldo prezzi prestazioni';
            if BankAccRecLine."Bank Account No." in ['1025', '1026'] then
                TransactionText += ' CS'
            else
                TransactionText += ' UBS';
        end;
    end;

    local procedure CheckTrapassoText(BankAccRecLine: record "Bank Acc. Reconciliation Line"; var TransactionText: text)
    var
        desc1: Text;
        desc2: Text;
        desc3: Text;
        BankAcc: Record "Bank Account";
        CurrCode: Code[5];
    begin
        desc1 := UpperCase(BankAccRecLine."AVU Description 1");
        desc2 := UpperCase(BankAccRecLine."AVU Description 2");
        desc3 := UpperCase(BankAccRecLine."AVU Description 3");
        BankAcc.get(BankAccRecLine."Bank Account No.");
        CurrCode := BankAcc."Currency Code";
        IF CurrCode = '' then
            CurrCode := 'EUR';
        if (StrPos(desc1, UpperCase('Vendita divise')) <> 0) and
           (StrPos(desc3, 'AVU SA') <> 0)
        then
            TransactionText := 'AVU SA Trapasso' + ' ' + CurrCode + ' ' + Format(BankAccRecLine."Statement Amount");

        if (StrPos(desc1, UpperCase('Bonifico')) <> 0) and
           (StrPos(desc2, 'AVU SA') <> 0)
        then
            TransactionText := 'AVU SA Trapasso' + ' ' + CurrCode + ' ' + Format(BankAccRecLine."Statement Amount");

        if (StrPos(desc1, UpperCase('Compera divise')) <> 0) and
           (StrPos(desc3, 'AVU SA') <> 0)
        then
            TransactionText := 'AVU SA Trapasso' + ' ' + CurrCode + ' ' + Format(BankAccRecLine."Statement Amount");
    end;

    local procedure SearchDocNo(BankAccRecLine: record "Bank Acc. Reconciliation Line") DocNo: text
    begin
        DocNo := GetPOSONo(BankAccRecLine."AVU Description 1");
        if DocNo = '' then
            DocNo := GetPOSONo(BankAccRecLine."AVU Description 2");
        if DocNo = '' then
            DocNo := GetPOSONo(BankAccRecLine."AVU Description 3");
        exit(DocNo);
    end;

    procedure GetPOSONo(Desc: Text) DocNo: text;
    var
        pos: Integer;
        desc2: text;
        i: Integer;
    begin
        DocNo := '';
        desc2 := desc;
        repeat
            POS := strpos(desc2, 'PO-');
            if pos <> 0 then begin
                if i = 0 then
                    DocNo := CopyStr(desc2, pos, 12)
                else
                    DocNo += ',' + CopyStr(desc2, pos, 12);

                desc2 := CopyStr(desc2, pos + 12);
                i += 1;
            end;

        until pos = 0;

        desc2 := desc;
        repeat
            POS := strpos(desc2, 'SO-');
            if pos <> 0 then begin
                if i = 0 then
                    DocNo := CopyStr(desc2, pos, 11)
                else
                    DocNo += ',' + CopyStr(desc2, pos, 11);

                desc2 := CopyStr(desc2, pos + 11);
                i += 1;
            end;
        until pos = 0;
    end;

    procedure ClearTransactionText(var BankAccRecLine: record "Bank Acc. Reconciliation Line")

    begin
        //BankAccRecLine.SetRange("Bank Account No.", BankAccNoCode);
        if BankAccRecLine.FindSet(true, false) then
            repeat
                BankAccRecLine.VALIDATE("Transaction Text", '');
                BankAccRecLine.Modify();
            until BankAccRecLine.next = 0;
    end;

    var
        myInt: Integer;
}
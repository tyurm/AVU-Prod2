pageextension 82009 "AVU Payment Reconcil. Journal" extends "Payment Reconciliation Journal"
{
    layout
    {
        modify(Control1)
        {
            FreezeColumn = "AVU Description 3";
        }

        addafter("Statement Amount")
        {
            field("AVU Description 1"; "AVU Description 1")
            {
                ApplicationArea = All;
            }
            field("AVU Description 2"; "AVU Description 2")
            {
                ApplicationArea = All;
            }
            field("AVU Description 3"; "AVU Description 3")
            {
                ApplicationArea = All;
            }
        }

    }

    actions
    {


        addlast(Process)
        {




            action(ApplySelectionAutomatically)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Selection Automatically';
                Image = MapAccounts;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunPageOnRec = true;
                ToolTip = 'Apply payments to their related open entries based on data matches between bank transaction text and entry information.';

                trigger OnAction()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                    BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                    MatchBankPayments: Codeunit "Match Bank Payments 2";
                begin
                    // AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
                    // AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
                    // AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");

                    // if AppliedPaymentEntry.Count > 0 then
                    //     if not Confirm(RemoveExistingApplicationsQst) then
                    //         exit;

                    //BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
                    //BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
                    CurrPage.SetSelectionFilter(BankAccReconciliationLine);
                    IF BankAccReconciliationLine.FINDFIRST THEN BEGIN
                        MatchBankPayments.SetApplyEntries(TRUE);
                        MatchBankPayments.RUN(BankAccReconciliationLine);
                    END;
                    CurrPage.Update(false);
                end;

            }
            action("Parse AVU Descriptions")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ParseMgt: Codeunit "Parse Bank Transaction Mgt.";
                    SelectedBankAccRec: Record "Bank Acc. Reconciliation Line";
                begin
                    CurrPage.SetSelectionFilter(SelectedBankAccRec);
                    ParseMgt.FillTransactionTextFromDescription(SelectedBankAccRec);
                end;
            }
            action("AVU Clear Transaction Text")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectedBankAccRec: Record "Bank Acc. Reconciliation Line";
                    ParseMgt: Codeunit "Parse Bank Transaction Mgt.";
                begin
                    CurrPage.SetSelectionFilter(SelectedBankAccRec);
                    ParseMgt.ClearTransactionText(SelectedBankAccRec);
                end;
            }
            action(UpdateTransactionText)
            {

                ApplicationArea = Basic, Suite;
                Caption = 'Update Transaction Text';
                Image = CheckRulesSyntax;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunPageOnRec = true;
                ToolTip = 'Update field "Transaction Text" based on the template: "Vendor/Customer Name" + applied "Document No". For all lines in the batch.';
                trigger OnAction()
                var
                    ParseBankAccMgt: Codeunit "Parse Bank Transaction Mgt.";
                begin
                    If Dialog.Confirm(UpdateTransactionTextQst, false) then
                        ParseBankAccMgt.UpdateTransactionText(Rec);
                end;
            }
        }
    }


    var
        UpdateTransactionTextQst: Label '"Transaction Text" will be updated for all lines in the statement. Continue?';

}
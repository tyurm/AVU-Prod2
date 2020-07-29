pageextension 82024 MyExtension extends "Pmt. Reconciliation Journals"
{
    layout
    {
        // Add changes to page layout here
        addafter("Bank Account No.")
        {
            field("Bank Acc. Name"; BankAccName)
            {
                ApplicationArea = All;
            }
        }
    }


    trigger OnAfterGetRecord()
    var
        BankAcc: Record "Bank Account";
    begin
        If BankAcc.get(Rec."Bank Account No.") then
            BankAccName := BankAcc.Name;
    end;

    var
        BankAccName: Text[80];

}
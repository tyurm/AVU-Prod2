page 82090 "AVU Tables"
{
    Caption = 'Tables';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "AVU Table";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = All;
                }
                field("No. of Records"; "No. of Records")
                {
                    ApplicationArea = All;
                }
                field("No. of Table Relation Errors"; "No. of Table Relation Errors")
                {
                    ApplicationArea = All;
                }
                field("Delete Records"; "Delete Records")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert/Update Tables")
                {
                    Caption = 'Insert/Update Tables';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        RecordDeletionMgt.InsertUpdateTables();
                    end;
                }
                action("Calculate Records")
                {
                    Caption = 'Calculate Records';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        AVUTable: Record "AVU Table";
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(AVUTable);
                        RecordDeletionMgt.CountRecords(AVUTable);
                    end;
                }
                action("Suggest Records to Delete")
                {
                    Caption = 'Suggest Records to Delete';
                    Image = Suggest;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        RecordDeletionMgt.SuggestRecordsToDelete();
                    end;
                }
                action("Clear Records to Delete")
                {
                    Caption = 'Clear Records to Delete';
                    Image = ClearLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        RecordDeletionMgt.ClearRecordsToDelete();
                    end;
                }
                action("DeleteRecords")
                {
                    Caption = 'Delete Records';
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        RecordDeletionMgt.DeleteRecords();
                    end;
                }
                action("Check Table Relations")
                {
                    Caption = 'Check Table Relations';
                    Image = Relationship;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        AVUTable: Record "AVU Table";
                        RecordDeletionMgt: Codeunit "AVU Record Deletion Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(AVUTable);
                        RecordDeletionMgt.CheckTableRelations(AVUTable);
                    end;
                }
                action("View Records")
                {
                    Caption = 'View Records';
                    Image = "Table";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        TableRecords: Page "AVU Table Records";
                    begin
                        TableRecords.Load("Table ID");
                        TableRecords.Run();
                    end;
                }
            }
        }
    }
}


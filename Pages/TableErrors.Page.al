page 82091 "AVU Table Errors"
{
    Caption = 'Table Errors';
    Editable = false;
    PageType = List;
    SourceTable = "AVU Table Error";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = All;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = All;
                }
                field(Error; Error)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}


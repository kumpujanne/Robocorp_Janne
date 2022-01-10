*** Settings ***
Documentation     Orders new robots from RobotSpareBin Industries Inc.
...               Saves bots details from receipt and screenshot of the bot to a PDF.
...               Creates ZIP file of all receipts
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Check who runs
    Open order webpage
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close POPUP
        Process an order    ${row}
        ${receipt}=    Save receipt    ${row}
        ${bot}=    Save picture    ${row}
        FinalizePDF    ${receipt}    ${bot}
        Order new
    END
    [Teardown]    Close the browser
    Zip Up

*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true
    ${table_orders}=    Read table from CSV    orders.csv
    [Return]    ${table_orders}

Open order webpage
    ${roboturl}=    Get Secret    targetURL
    Open Available Browser    ${roboturl}[orderURL]

Close POPUP
    Click Button    OK

Process an order
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    15x    1s    Finalize order

Order new
    Click Button    id:order-another

Save receipt
    [Arguments]    ${row}
    Set Local Variable    ${receipt_pdf}    ${OUTPUT_DIR}${/}receipts${/}receipt${row}[Order number].pdf
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${receipt_pdf}
    [Return]    ${receipt_pdf}

Save picture
    [Arguments]    ${row}
    Set Local Variable    ${bot_pic}    ${OUTPUT_DIR}${/}image${row}[Order number].png
    Screenshot    robot-preview-image    ${bot_pic}
    [Return]    ${bot_pic}

FinalizePDF
    [Arguments]    ${receipt}    ${bot}
    Log To Console    Combining receipt at: ${receipt} with pic at: ${bot}
    ${imageList}=    Create List    ${bot}
    Open Pdf    ${receipt}
    Add Files To Pdf    ${imageList}    ${receipt}    True
    Close Pdf    ${receipt}
    Remove File    ${bot}

Finalize order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Close the browser
    Close Browser

Zip Up
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}results.zip
    Empty Directory    ${OUTPUT_DIR}${/}receipts

Check who runs
    Add heading    Welcome to Bot order
    Add text input    who    label=Who is placing an order?    placeholder=Type your name here, please
    ${result}=    Run dialog
    Log To Console    ${result.who} has requested a new batch of bots! Way to go ${result.who}!

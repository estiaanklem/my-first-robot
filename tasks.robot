*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Excel.Files
Library             RPA.Tables
Library             Screenshot
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries
    ${file_path}=    Get orders from user
    Open robot order website
    ${orders}=    Read orders from file    ${file_path}
    FOR    ${row}    IN    @{orders}
        Close purple pop-up
        Fill in order from    ${row}
        Preview robot order
        ${is_receipt_visible}=    Is Element Visible    receipt
        WHILE    ${is_receipt_visible}==${False}
            Submit robot order
            ${is_receipt_visible}=    Is Element Visible    receipt
            IF    ${is_receipt_visible}                BREAK
            Sleep    0.5
        END
        # Wait Until Keyword Succeeds    10x    2 sec    Submit robot order
        ${pdf}=    Save receipt as PDF    ${row}[Order number]
        ${screenshot}=    Take screenshot of robot    ${row}[Order number]
        Embed robot image in receipt PDF    ${screenshot}    ${pdf}
        Order another robot
    END
    Create ZIP file of receipts
    Clean up step


*** Keywords ***
Open robot order website
    ${url}=    Get Secret    url
    Open Available Browser    ${url}[link]

Get orders
    Download    https://robotsparebinindustries.com/orders.csv
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Get orders from user
    Add heading    Upload Orders CSV
    Add file input
    ...    label=Upload the csv with orders data
    ...    name=csvupload
    ...    file_type=csv (*.csv)
    ...    destination=output
    ${response}=    Run dialog
    RETURN    ${response.csvupload}[0]

Read orders from file
    [Arguments]    ${file_path}
    ${orders}=    Read table from CSV    ${file_path}
    RETURN    ${orders}

Close purple pop-up
    Click Button When Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill in order from
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Button    css:#id-body-${row}[Body]
    Input Text    css:input[placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview robot order
    Click Button    preview

Submit robot order
    Click Button    order

Save receipt as PDF
    [Arguments]    ${number}
    ${output_path}=    Set Variable    ${OUTPUT_DIR}${/}Receipts${/}Receipt ${number}.pdf
    Wait Until Element Is Visible    receipt
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html to PDF    ${receipt_html}    ${output_path}
    RETURN    ${output_path}

Take screenshot of robot
    [Arguments]    ${number}
    ${output_path}=    Set Variable    ${OUTPUT_DIR}${/}Robot Previews${/}robot-preview ${number}.png
    Wait Until Page Contains Element    robot-preview-image
    Screenshot    robot-preview-image    ${output_path}
    RETURN    ${output_path}

Embed robot image in receipt PDF
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Order another robot
    Click Button    order-another

Create ZIP file of receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}Receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${zip_file_name}

Clean up step
    Empty Directory    ${OUTPUT_DIR}${/}Receipts
    Empty Directory    ${OUTPUT_DIR}${/}Robot Previews
    Close Browser

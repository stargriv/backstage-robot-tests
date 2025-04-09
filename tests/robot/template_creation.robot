*** Settings ***
Documentation     Test for creating a new project using Backstage template
Library           SeleniumLibrary
Library           OperatingSystem
Library           RequestsLibrary
Suite Setup       Open Browser And Login
Suite Teardown    Close All Browsers

*** Variables ***
${SERVER}         localhost:7007
${BROWSER}        chrome
${DELAY}          0.5
${LOGIN_TIMEOUT}  1
${TIMEOUT}        1
${LOGIN_URL}      http://${SERVER}/
${CREATE_URL}     http://${SERVER}/create/templates/default/example-nodejs-template
${COMPONENT_URL}  http://${SERVER}/catalog/default/component/test-project
${TEMPLATE_NAME}  test-project
${GITHUB_TOKEN}   %{GITHUB_TOKEN}
${OWNER}          stargriv
${REPO_NAME}      test-project
${DESCRIPTION}    Test project created by automation

*** Keywords ***
Wait Until Page Contains Element Or Text
    [Arguments]    ${element}    ${text}    ${timeout}
    ${status}=    Run Keyword And Return Status    
    ...    Wait Until Page Contains Element    ${element}    ${timeout}
    Run Keyword If    not ${status}    
    ...    Wait Until Page Contains    ${text}    ${timeout}
    [Return]    ${status}

Open Browser And Login
    Open Browser    ${LOGIN_URL}    ${BROWSER}
    Set Selenium Speed    ${DELAY}
    Set Selenium Timeout    ${TIMEOUT}
    Maximize Browser Window
    
    # Wait for the page to load
    Wait Until Element Is Visible    id:root    ${LOGIN_TIMEOUT}
    
    # Handle various possible states
    ${enter_visible}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    xpath://*[@id="root"]/main/article/ul/li/div/div[3]/button    1s
    Run Keyword If    ${enter_visible}    Click Element    xpath://*[@id="root"]/main/article/ul/li/div/div[3]/button
    

    # Wait for successful login - checking multiple possible elements
    Wait Until Keyword Succeeds    ${LOGIN_TIMEOUT}s    1s    
    ...    Wait Until Page Contains Element Or Text    
    ...    xpath://a[contains(@href, '/catalog')] | //a[contains(@aria-label, 'Home')] | //div[contains(@class, 'sidebar')]    
    ...    Welcome to Backstage    
    ...    ${LOGIN_TIMEOUT}
    
    # Navigate to template page and verify
    Go To    ${CREATE_URL}
    Location Should Be    ${CREATE_URL}
    Wait Until Element Is Visible    xpath://*[@id="root"]/div/main/article/div/div[1]/div/h2    ${TIMEOUT}

Verify Form Step
    [Arguments]    ${step_title}
    Wait Until Element Is Visible    css:h1    1s
    Element Should Contain    css:h2    ${step_title}

Verify Next Step
    [Arguments]    ${step_title}
    Wait Until Element Is Visible   css:h5     1s
    Element Should Contain    css:h5    ${step_title}

Fill Template Form
    
    # Step 1: Fill Project Details
    Verify Form Step    Example Node.js Template
    
    # Fill out project name
    Wait Until Element Is Enabled    css:input[name='root_name']    1s
    Input Text    css:input[name='root_name']    ${TEMPLATE_NAME}
    
    # Fill description if field exists
    ${desc_exists}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    css:textarea[name='description']    1s
    Run Keyword If    ${desc_exists}    Input Text    css:textarea[name='description']    ${DESCRIPTION}
    
    # Click Next
    Click Next Button
    
    # Step 2: Repository Information
    Verify Next Step    Repository Location
    
    Wait Until Element Is Enabled   xpath=//label[contains(text(), 'Owner')]/following::input   1s
    Input Text    xpath=//label[contains(text(), 'Owner')]/following::input    ${OWNER}
    Input Text    xpath=//label[contains(text(), 'Repository')]/following::input    ${REPO_NAME}
        
    # Click Review Button
    Click Next Button
    
    # Click Create
    Wait Until Element Is Enabled    xpath://*[@id="root"]/div/main/article/div/div[2]/div[2]/div/button[2]    1s
    Click Element   xpath://*[@id="root"]/div/main/article/div/div[2]/div[2]/div/button[2]

Click Next Button
    Wait Until Element Is Enabled    xpath://*[@id="root"]/div/main/article/div/div[2]/div[2]/form/div[2]/button[2]    1s
    Click Element    xpath://*[@id="root"]/div/main/article/div/div[2]/div[2]/form/div[2]/button[2]

Verify Creation Success
    Wait Until Page Contains Element    xpath=//a[contains(.,'Repository')]    timeout=10s

Delete Backstage Component
    Go To    ${COMPONENT_URL}
    Location Should Be    ${COMPONENT_URL}

    Click Element    id=long-menu

    Click Element    xpath=//li[.//span[text()='Unregister entity']]

    Click Element    xpath=//button[.//span[text()='Unregister Location']]

Delete GitHub Repository
    # Create a session with GitHub API
    Create Session    github    https://api.github.com    verify=True
    
    # Set headers with authorization token
    ${headers}=    Create Dictionary
    ...    Authorization=token ${GITHUB_TOKEN}
    ...    Accept=application/vnd.github.v3+json

    # Send DELETE request to delete the repository
    ${response}=    DELETE On Session
    ...    github
    ...    /repos/${OWNER}/${REPO_NAME}
    ...    headers=${headers}
    ...    expected_status=204
    
    # Verify the repository was deleted successfully (204 No Content)
    try:
        Should Be Equal As Strings    ${response.status_code}    204
        Log    Repository '${REPO_NAME}' has been successfully deleted.
    except AssertionError as e:
        Log    Failed to delete repository '${REPO_NAME}': ${e}

*** Test Cases ***
Create New Project From Template
    [Documentation]    Creates a new project using the Node.js template
    [Tags]    template    create    nodejs
    Fill Template Form
    Verify Creation Success
    Delete Backstage Component
    Delete GitHub Repository

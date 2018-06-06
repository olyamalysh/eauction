*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  eauction_service.py

*** Variables ***
${host}=  eauction.byustudio.in.ua

*** Keywords ***

Підготувати клієнт для користувача
    [Arguments]  ${username}
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
#    Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=my_alias
    Run Keyword If  '${USERS.users['${username}'].browser}' in 'Chrome chrome'  Run Keywords
    ...  Call Method  ${chrome_options}  add_argument  --headless
    ...  AND  Create Webdriver  Chrome  alias=my_alias  chrome_options=${chrome_options}
    ...  AND  Go To  ${USERS.users['${username}'].homepage}
    ...  ELSE  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=my_alias
    Set Window Size  ${USERS.users['${username}'].size[0]}  ${USERS.users['${username}'].size[1]}
    Run Keyword If  '${username}' != 'eauction_Viewer'  Run Keywords
    ...  Авторизація  ${username}
    ...  AND  Run Keyword And Ignore Error  Закрити Модалку
#    Авторизація  ${username}
    Run Keyword And Ignore Error  Закрити Модалку


Підготувати дані для оголошення тендера
    [Arguments]  ${username}  ${initial_tender_data}  ${role}
    ${tender_data}=  prepare_tender_data  ${role}  ${initial_tender_data}
    [Return]  ${tender_data}


Оновити сторінку з тендером
    [Arguments]  ${tender_uaid}  ${username}
    Switch Browser  my_alias
    Reload Page


Авторизація
    [Arguments]  ${username}
    Click Element  xpath=//*[contains(@href, "/login")]
    Wait Until Element Is Visible  xpath=//button[@name="login-button"]
    Input Text  xpath=//input[@id="loginform-username"]  ${USERS.users['${username}'].login}
    Input Text  xpath=//input[@id="loginform-password"]  ${USERS.users['${username}'].password}
    Click Element  xpath=//button[@name="login-button"]


###############################################################################################################
########################################### ASSETS ############################################################
###############################################################################################################

Створити об'єкт МП   # !!!
    [Arguments]  ${username}  ${tender_data}
    ${data}=  Get Data  ${tender_data}
    ${decisions}=   Get From Dictionary   ${tender_data.data}   decisions
    ${items}=  Get From Dictionary  ${tender_data.data}  items
    Click Element  xpath=//button[@data-target="#toggleRight"]
    Wait Until Element Is Visible  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    Click Element  xpath=//nav[@id="toggleRight"]/descendant::a[contains(@href, "/assets/index")]
    eauction.Закрити Модалку
    Click Element  xpath=//a[contains(@href, "/buyer/asset/create")]
    Input Text  id=asset-title  ${data.title}
    Input Text  id=asset-description  ${data.description}
    Input Text  id=decision-0-title  ${decisions[0].title}
    Input Text  id=decision-0-decisionid  ${decisions[0].decisionID}
    ${decision_date}=  convert_date_for_decision  ${decisions[0].decisionDate}
    Input Text  id=decision-0-decisiondate  ${decision_date}
    ${items_length}=  Get Length  ${items}
    :FOR  ${item}  IN RANGE  ${items_length}
    \  Log  ${items[${item}]}
    \  Run Keyword If  ${item} > 0  Scroll To And Click Element  xpath=//button[@id="add-item"]
    \  Додати Предмет МП  ${items[${item}]}
    Select From List By Index  id=contact-point-select  1
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    ${auction_id}=  Get Text  xpath=//div[@data-test-id="tenderID"]
    [Return]  ${auction_id}


Додати предмет МП  # !!!
    [Arguments]  ${item_data}
    ${item}=   Get Element Attribute   xpath=(//textarea[contains(@class, "item-description") and not (contains(@id, "__empty__"))])[last()]@id
    ${item}=  Set Variable  ${item.split('-')[1]}
    Input Text  xpath=//*[@id="asset-${item}-description"]  ${item_data.description}
    Convert Input Data To String  xpath=//*[@id="asset-${item}-quantity"]  ${item_data.quantity}
    ${classification_scheme}=  Convert To Lowercase  ${item_data.classification.scheme}
    Click Element  xpath=//*[@id="classification-${item}-description"]
    Wait Until Element Is Visible  xpath=//*[@class="modal-title"]
    Input Text  xpath=//*[@placeholder="Пошук по коду"]  ${item_data.classification.id}
    Wait Until Element Is Visible  xpath=//*[@id="${item_data.classification.id}"]
    Scroll To And Click Element  xpath=//*[@id="${item_data.classification.id}"]
    Wait Until Element Is Enabled  xpath=//button[@id="btn-ok"]
    Click Element  xpath=//button[@id="btn-ok"]
    Wait Until Element Is Not Visible  xpath=//*[@class="fade modal"]
    Wait Until Element Is Visible  xpath=//*[@id="unit-${item}-code"]
    Select From List By Value  xpath=//*[@id="unit-${item}-code"]  ${item_data.unit.code}
    Select From List By Value  xpath=//*[@id="address-${item}-countryname"]  ${item_data.address.countryName}
    Scroll To  xpath=//*[@id="address-${item}-region"]
    Select From List By Value  xpath=//*[@id="address-${item}-region"]  ${item_data.address.region.replace(u' область', u'')}
    Input Text  xpath=//*[@id="address-${item}-locality"]  ${item_data.address.locality}
    Input Text  xpath=//*[@id="address-${item}-streetaddress"]  ${item_data.address.streetAddress}
    Input Text  xpath=//*[@id="address-${item}-postalcode"]  ${item_data.address.postalCode}
    Select From List By Value  id=registration-${item}-status  ${item_data.registrationDetails.status}


Додати актив до об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${item_data}
    eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Click Element  xpath=//button[@id="add-item-to-asset"]
    Run Keyword And Ignore Error  eauction.Додати предмет МП  ${item_data}
    Run Keyword And Ignore Error  eauction.Scroll To And Click Element   xpath=//button[@value="save"]


Пошук об’єкта МП по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Click Element  xpath=//*[@id="h-menu"]/descendant::a[contains(@href, "assets/index")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Input Text  id=assetssearch-asset_cbd_id  ${tender_uaid}
    Click Element  xpath=//button[contains(text(), "Шукати")]
    Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../../div[2]/a[contains(@href, "/asset/view")]
    ...  AND  Wait Until Element Is Not Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../../div[2]/a[contains(@href, "/asset/view")]
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]  20

Оновити сторінку з об'єктом МП
    [Arguments]  ${username}  ${tender_uaid}
    eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}

Внести зміни в об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
    eauction.Пошук об’єкта МП по ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Run Keyword If  '${fieldname}' == 'title'  Input Text  id=asset-title  ${fieldvalue}
    ...  ELSE IF  '${fieldname}' == 'description'  Input Text  id=asset-description  ${fieldvalue}
    ...  ELSE  Input Text  xpath=//*[@id="${field_name}"]  ${field_value}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]


Внести зміни в актив об'єкта МП
    [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${field_name}  ${field_value}
    eauction.Пошук об’єкта МП по ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    ${quantity}=  Convert To String  ${field_value}
    Run Keyword If   '${field_name}' == 'quantity'  Input Text  xpath=//textarea[contains(@data-old-value, "${item_id}")]/../../following-sibling::div/descendant::input[contains(@id, "quantity")]  ${quantity}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]


Завантажити документ для видалення об'єкта МП  # !!!
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}
    eauction.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${file_path}  cancellationDetails


Завантажити ілюстрацію в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  eauction.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${filepath}  illustration


Завантажити документ в об'єкт МП з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${last_input_number}=  Get Element Attribute  xpath=(//select[contains(@class, "document-related-item") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  id=document-${last_input_number}-title  ${file_path.split('/')[-1]}
    Select From List By Value  id=document-${last_input_number}-documenttype  ${doc_type}
    Select From List By Label  id=document-${last_input_number}-relateditem  Загальний
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Видалити об'єкт МП  # !!!
    [Arguments]  ${username}  ${tender_uaid}
    eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  id=delete_btn
    Wait Until Element Is Visible  xpath=//div[@class="modal-footer"]
    Click Element  xpath=//button[@data-bb-handler="confirm"]
    Wait Until Element Is Visible  //div[contains(@class,'alert-success')]



Отримати інформацію із об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If  '${field}' == 'assetCustodian.identifier.legalName'  Fail    ***** Офіційне ім’я замовника не виводиться на EAUCTION (відповідає найменуванню замовника) *****
    ...  ELSE IF  '${field}' == 'assetCustodian.identifier.scheme'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на eauction.byustudio.in.ua
    ...  ELSE IF  'assetHolder' in '${field}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на eauction.byustudio.in.ua
    ...  ELSE IF  'status' in '${field}'  Get Element Attribute  xpath=//input[@id="asset_status"]@value
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id="item.description"]
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//a[contains(@href, "info/ssp_details")]/../following-sibling::div[1]
    ...  ELSE IF  'rectificationPeriod' in '${field}'  Get Text  xpath=//div[@data-test-id="rectificationPeriod"]
    ...  ELSE IF  'decisions' in '${field}'  Отримати інформацію про decisions  ${field}
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field.replace('assetCustodian', 'procuringEntity')}']
    ${value}=  adapt_asset_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію з активу об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
#    Run Keyword If  'description' in '${field}'  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ${field}=  Set Variable If  '[' in '${field}'  ${field.split('[')[0]}${field.split(']')[1]}  ${field}
    ${value}=  Run Keyword If
    ...  '${field}' == 'classification.scheme'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::div[@data-test-id="item.classification.scheme"]
    ...  ELSE IF  '${field}' == 'additionalClassifications.description'  Get Text  xpath=//*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[text()='PA01-7']/following-sibling::span
    ...  ELSE IF  'description' in '${field}'  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="asset.item.${field}"]
    ...  ELSE IF  'registrationDetails.status' in '${field}'  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.address.status"]
    ...  ELSE  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.${field}"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Отримати кількість активів в об'єкті МП
  [Arguments]  ${username}  ${tender_uaid}
  eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  ${number_of_items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="asset.item.description"]
  ${number_of_items}=  Convert To Integer  ${number_of_items}
  [Return]  ${number_of_items}


Отримати інформацію про decisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.title"])["${index + 1}"]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.decisionDate"])["${index + 1}"]
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=(//div[@data-test-id="asset.decision.decisionID"])["${index + 1}"]
  [Return]  ${value}


############################################## ЛОТИ #######################################

Створити лот
  [Arguments]  ${username}  ${tender_data}  ${asset_uaid}
  eauction.Пошук об’єкта МП по ідентифікатору  ${username}  ${asset_uaid}
  Click Element  xpath=//a[contains(text(), "Створити лот")]
  ${decision_date}=  convert_date_for_decision  ${tender_data.data.decisions[0].decisionDate}
  Input Text   name=Lot[decisions][0][title]  Title
  Input Text   name=Lot[decisions][0][decisionDate]   ${decision_date}
  Input Text   name=Lot[decisions][0][decisionID]   ${tender_data.data.decisions[0].decisionID}

  Input Text  name=Lot[auctions][0][value][amount]  10
  Input Text  name=Lot[auctions][0][minimalStep][amount]  10
  Input Text  name=Lot[auctions][0][guarantee][amount]  10
  Input Text  name=Lot[auctions][0][registrationFee][amount]  17
  Click Element  name=Lot[auctions][0][auctionPeriod][startDate]

  Input Text  name=Lot[auctions][1][tenderingDuration]  30

  Input Text  name=Lot[auctions][2][auctionParameters][dutchSteps]  99

  Click Element  name=simple_submit
  Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]  20
  ${lot_id}=  Get Text  xpath=//div[@data-test-id="lotID"]
  [Return]  ${lot_id}


Заповнити дані для першого аукціону
#  [Arguments]  ${auction}
#  ${value_amount}=  add_second_sign_after_point  ${auction.value.amount}
#  ${minimalStep_amount}=  add_second_sign_after_point  ${auction.minimalStep.amount}
#  ${guarantee_amount}=  add_second_sign_after_point  ${auction.guarantee.amount}
#  Input Text  name=data[auctions][0][value][amount]  ${value_amount}
#  Input Text  name=data[auctions][0][minimalStep][amount]  ${minimalStep_amount}
#  Input Text  name=data[auctions][0][guarantee][amount]  ${guarantee_amount}
#  Input Date  data[auctions][0][auctionPeriod][startDate]  ${auction.auctionPeriod.startDate}



Додати умови проведення аукціону
  [Arguments]  ${username}  ${auction}  ${index}  ${tender_uaid}
  Wait Until Keyword Succeeds  15 x   20 s   Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Page Contains Element  xpath=//div[@data-test-id="status"][contains(text(), "lot.status.pending")]
  Log  ERROR
#  dzo.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
#  Wait Until Keyword Succeeds  15 x   20 s   Run Keywords
#  ...  Reload Page
#  ...  AND  Wait Until Page Contains Element  xpath=//a[./text()='Редагувати']
#  Клікнути по елементу   xpath=//a[./text()='Редагувати']
#  Клікнути по елементу  xpath=(//section[contains(@class, "accordionItem")]/a)[3]
#
#  Run Keyword If  ${index} == 0  Заповнити дані для першого аукціону  ${auction}
#
#
#  Run Keyword If  ${index} == 1  Select From List By Value  name=data[auctions][1][tenderingDuration]  30
#
#
#  Run Keyword If  ${index} == 2  Run Keywords
#  ...  Input Text  name=data[auctions][2][value][amount]  ${value_amount}
#  ...  AND  Input Text  name=data[auctions][2][minimalStep][amount]  ${minimalStep_amount}
#  ...  AND  Input Text  name=data[auctions][2][guarantee][amount]  ${guarantee_amount}
#
#  Клікнути по елементу  xpath=//button[@value="save"]
#  Wait Until Element Is Visible  ${locator.tenderId}


Пошук лоту по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Click Element  xpath=//button[@data-target="#toggleRight"]
    Wait Until Element Is Visible  xpath=//a[contains(@href, "/buyer/lots/index")]
    Click Element  xpath=//a[contains(@href, "/buyer/lots/index")]
    Input Text  id=lotssearch-lot_cbd_id  ${tender_uaid}
    Click Element  xpath=//button[contains(text(), "Шукати")]
    Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    ...  AND  Wait Until Element Is Not Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]  20


Оновити сторінку з лотом
    [Arguments]  ${username}  ${tender_uaid}
    eauction.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}


Отримати інформацію із лоту
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If  '${field}' == 'assetCustodian.identifier.legalName'  Fail    ***** Офіційне ім’я замовника не виводиться на EAUCTION (відповідає найменуванню замовника) *****
    ...  ELSE IF  '${field}' == 'assetCustodian.identifier.scheme'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на eauction.byustudio.in.ua
    ...  ELSE IF  'assetHolder' in '${field}'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на eauction.byustudio.in.ua
    ...  ELSE IF  'status' in '${field}'  Get Text  xpath=//div[@data-test-id="status"]
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[@data-test-id="tenderID"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id="item.description"]
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//a[contains(@href, "info/ssp_details")]/../following-sibling::div[1]
    ...  ELSE IF  'decisions' in '${field}'  Отримати інформацію про lot decisions  ${field}
    ...  ELSE IF  'assets[0]' in '${field}'  Отримати інформацію про related asset
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field.replace('assetCustodian', 'procuringEntity')}']
    ${value}=  adapt_asset_data  ${field}  ${value}
    [Return]  ${value}


Отримати інформацію про lot decisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=//div[@class="item-inf_t"][contains(text(), "Рішення про приватизацію")]/following-sibling::div/div[${index + 1}]/div[1]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=//div[@class="item-inf_t"][contains(text(), "Рішення про приватизацію")]/following-sibling::div/div[${index + 1}]/div[3]
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=//div[@class="item-inf_t"][contains(text(), "Рішення про приватизацію")]/following-sibling::div/div[${index + 1}]/div[2]
  ${value}=  Set Variable  ${value.split(':')[-1]}
  [Return]  ${value}

Отримати інформацію про related asset
    ${item}=  Get Text  xpath=//div[@class="item-inf_t"][contains(text(), "Активи")]/following-sibling::div/div/div/b
    [Return]  ${item.split(':')[0]}


Завантажити ілюстрацію в лот
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  eauction.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${filepath}  illustration


Завантажити документ в лот з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    eauction.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(@href, "asset/update")]
    Wait Until Element Is Visible  xpath=//form[@id="asset-form"]
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Sleep  2
    ${last_input_number}=  Get Element Attribute  xpath=(//select[contains(@class, "document-related-item") and not (contains(@id, "__empty__"))])[last()]@id
    ${last_input_number}=  Set Variable  ${last_input_number.split('-')[1]}
    Input Text  id=document-${last_input_number}-title  ${file_path.split('/')[-1]}
    Select From List By Value  id=document-${last_input_number}-documenttype  ${doc_type}
    Select From List By Label  id=document-${last_input_number}-relateditem  Загальний
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10
##################################################################################


Створити тендер
    [Arguments]  ${tender_owner}  ${tender_data}
    ${data}=  Get Data  ${tender_data}
    ${items}=  Get From Dictionary  ${tender_data.data}  items
    Click Element  xpath=//li[@class="dropdown"]/descendant::*[@class="dropdown-toggle"][contains(@href, "tenders")]
    Click Element  xpath=//*[@class="dropdown-menu"]/descendant::*[contains(@href, "/tenders/index")]
    eauction.Закрити Модалку
    Click Element  xpath=//a[contains(@href, "/buyer/tender/create")]
    Select From List By Value  xpath=//select[@class="tender-rent-select"]  rent
    Convert Input Data To String  xpath=//input[@id="value-amount"]  ${tender_data.data.value.amount}
    Adapt And Select By Value  xpath=//select[@id="value-valueaddedtaxincluded"]  ${tender_data.data.value.valueAddedTaxIncluded}
    Convert Input Data To String  //input[@id="minimalstepvalue-amount"]  ${tender_data.data.minimalStep.amount}
    Convert Input Data To String  //input[@id="guarantee-amount"]  ${tender_data.data.guarantee.amount}
    Input Text  xpath=//*[@id="tender-title"]  ${tender_data.data.title}
    Input Text  xpath=//*[@id="tender-description"]  ${tender_data.data.description}
    Input Text  xpath=//*[@id="tender-dgfid"]  ${tender_data.data.dgfID}
    ${tenderAttempts}=  Convert To String  ${tender_data.data.tenderAttempts}
    Select From List By Value  xpath=//*[@id="tender-tenderattempts"]  ${tenderAttempts}
    ${minNumberOfQualifiedBids}=  Convert To String  ${tender_data.data.minNumberOfQualifiedBids}
    Select From List By Value  xpath=//*[@id="tender-minnumberofqualifiedbids"]  ${minNumberOfQualifiedBids}
    ${items_length}=  Get Length  ${items}
    :FOR  ${item}  IN RANGE  ${items_length}
    \  Log  ${items[${item}]}
    \  Run Keyword If  ${item} > 0  Scroll To And Click Element  xpath=//button[@id="add-item"]
    \  Додати Предмет  ${item}  ${items[${item}]}
    ${auction_date}=  convert_date_for_auction  ${data.auctionPeriod.startDate}
    Input Text  //*[@id="auction-start-date"]  ${auction_date}
    Input Text  //*[@id="contactpoint-name"]  ${data.procuringEntity.contactPoint.name}
    Input Text  //*[@id="contactpoint-email"]  ${data.procuringEntity.contactPoint.email}
    Input Text  //*[@id="contactpoint-telephone"]  '000${data.procuringEntity.contactPoint.telephone}'
    Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    ${auction_id}=  Get Text  xpath=//div[@data-test-id="tenderID"]
    [Return]  ${auction_id}


Додати Предмет
    [Arguments]  ${item}  ${item_data}
    Input Text  xpath=//*[@id="item-${item}-description"]  ${item_data.description}
    Convert Input Data To String  xpath=//*[@id="item-${item}-quantity"]  ${item_data.quantity}
    ${classification_scheme}=  Convert To Lowercase  ${item_data.classification.scheme}
    Select From List By Value  xpath=//*[@id="item-${item}-id"]/../../descendant::*[@id="classification-scheme"]  ${classification_scheme}
    Click Element  xpath=//*[@id="classification-${item}-description"]
    Wait Until Element Is Visible  xpath=//*[@class="modal-title"]
    Input Text  xpath=//*[@placeholder="Пошук по коду"]  ${item_data.classification.id}
    Wait Until Element Is Visible  xpath=//*[@id="${item_data.classification.id}"]
    Scroll To And Click Element  xpath=//*[@id="${item_data.classification.id}"]
    Wait Until Element Is Enabled  xpath=//button[@id="btn-ok"]
    Click Element  xpath=//button[@id="btn-ok"]
    Wait Until Element Is Not Visible  xpath=//*[@class="fade modal"]
    Wait Until Element Is Visible  xpath=//*[@id="unit-${item}-code"]
    Select From List By Value  xpath=//*[@id="unit-${item}-code"]  ${item_data.unit.code}
    Select From List By Value  xpath=//*[@id="deliveryaddress-${item}-countryname"]  ${item_data.address.countryName}
    Scroll To  xpath=//*[@id="deliveryaddress-${item}-region"]
    Select From List By Value  xpath=//*[@id="deliveryaddress-${item}-region"]  ${item_data.address.region.replace(u' область', u'')}
    Input Text  xpath=//*[@id="deliveryaddress-${item}-locality"]  ${item_data.address.locality}
    Input Text  xpath=//*[@id="deliveryaddress-${item}-streetaddress"]  ${item_data.address.streetAddress}
    Input Text  xpath=//*[@id="deliveryaddress-${item}-postalcode"]  ${item_data.address.postalCode}
    ${contract_start_date}=  convert_date_for_item  ${item_data.contractPeriod.startDate}
    ${contract_end_date}=  convert_date_for_item  ${item_data.contractPeriod.endDate}
    Input Text  xpath=//*[@id="itemcontractperiod-${item}-startdate"]  ${contract_start_date}
    Input Text  xpath=//*[@id="itemcontractperiod-${item}-enddate"]  ${contract_end_date}


Додати Предмет Закупівлі
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${item_data}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    eauction.Wait For Document Upload
    ${items}=  Get Matching Xpath Count  xpath=//span[@class="panel-title-item"]
    ${n_items}=  Convert To Integer  ${items}
    Scroll To And Click Element  xpath=//button[@id="add-item"]
    eauction.Додати Предмет  ${n_items}  ${item_data}
    Click Element  xpath=//*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    ...  AND  Compare Number Elements  ${n_items}



Видалити предмет закупівлі
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${item_id}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    eauction.Wait For Document Upload
    Run Keyword And Ignore Error  Click Element  xpath=(//button[contains(@class,'delete_item')])[last()]


Скасувати закупівлю
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${cancellation_reason}  ${file_path}  ${cancellation_description}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    Click Element  xpath=//*[@data-test-id="sidebar.cancell"]
    Select From List By Value  //*[@id="cancellation-relatedlot"]  tender
    Select From List By Label  //*[@id="cancellation-reason"]  ${cancellation_reason}
    Choose File  xpath=//*[@action="/tender/fileupload"]/input  ${file_path}
    Wait Until Element Is Visible  xpath=(//input[@class="file_name"])[last()]
    Input Text  xpath=(//input[@class="file_name"])[last()]  ${file_path.split('/')[-1]}
    Click Element  xpath=//button[@id="submit-cancel-auction"]
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.cancell"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//*[@data-test-id-cancellation-status="active"]



Внести зміни в тендер
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${field_name}  ${field_value}
    ${red}=  Evaluate  "\\033[1;31m"
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    Wait For Document Upload
    Run Keyword If
    ...  '_ru' in '${field_name}'  Log To Console  ${red}\n\t\t\t ***** SITENAME не підтримує локалізацію російською мовою *****
    ...  ELSE IF  '_en' in '${field_name}'  Log To Console  ${red}\n\t\t\t ***** SITENAME не підтримує локалізацію англійською мовою *****
    ...  ELSE IF  '${field_name}' == 'value.amount'  Convert Input Data To String  xpath=//input[@id="value-amount"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'minimalStep.amount'  Convert Input Data To String  xpath=//input[@id="minimalstepvalue-amount"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'guarantee.amount'  Convert Input Data To String  xpath=//input[@id="guarantee-amount"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'tenderPeriod.startDate'  Input Text  xpath=//*[@id="auction-start-date"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'title'  Input Text  xpath=//*[@id="tender-title"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'description'  Input Text  xpath=//*[@id="tender-description"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'tenderAttempts'  Select From List By Converted Value  xpath=//*[@id="tender-tenderattempts"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'dgfID'  Input Text  xpath=//*[@id="tender-dgfid"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'minimalStep.amount'  Convert Input Data To String  xpath=//input[@id="minimalstepvalue-amount"]  ${field_value}
    ...  ELSE IF  '${field_name}' == 'guarantee.amount'  Convert Input Data To String  xpath=//input[@id="guarantee-amount"]  ${field_value}
    ...  ELSE  Input Text  xpath=//*[@id="${field_name}"]  ${field_value}
    Scroll To And Click Element  //*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]



Редагувати ПДВ
    [Arguments]  ${tender_owner}  ${tender_uaid}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    Wait For Document Upload
    Select From List By Value  xpath=//select[@id="value-valueaddedtaxincluded"]  1
    Scroll To And Click Element  //*[@name="simple_submit"]



Завантажити документ
    [Arguments]  ${tender_owner}  ${file_path}  ${tender_uaid}
    eauction.Завантажити документ в тендер з типом  ${tender_owner}  ${tender_uaid}  ${file_path}  clarifications



Завантажити ілюстрацію
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${file_path}
    eauction.Завантажити документ в тендер з типом  ${tender_owner}  ${tender_uaid}  ${file_path}  illustration



Завантажити документ в тендер з типом
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${file_path}  ${doc_type}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    Wait For Document Upload
    Scroll To  xpath=//*[@action="/tender/fileupload"]/input
    Choose File  xpath=(//*[@action="/tender/fileupload"]/input)[last()]  ${file_path}
    Wait Until Element Is Visible  xpath=(//*[@class="document-title"])[last()]
    Input Text  xpath=(//*[@class="document-title"])[last()]  ${file_path.split('/')[-1]}
    Select From List By Value  xpath=(//*[@class="document-type"])[last()]  ${doc_type}
    Select From List By Value  xpath=(//*[@class="document-related-item"])[last()]  tender
    Scroll To And Click Element  xpath=//*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.edit"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Додати офлайн документ
    [Arguments]  ${tender_owner}  ${TENDER['TENDER_UAID']}  ${accessDetails}
    Wait For Document Upload
    Scroll To  xpath=//*[@data-type="x_dgfAssetFamiliarization"]
    Click Element  xpath=//*[@data-type="x_dgfAssetFamiliarization"]
    Input Text  xpath=(//*[@class="document-title"])[last()]  ${accessDetails}
    Input Text  xpath=(//*[@class="document-access-details"])[last()]  ${accessDetails}
    Scroll To And Click Element  xpath=//*[@name="simple_submit"]
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.edit"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Відповісти на запитання
    [Arguments]  ${tender_owner}  ${tender_uaid}  ${answer}  ${question_id}
    Run Keyword And Ignore Error  Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    eauction.Закрити Модалку
    Close Sidebar
    Input Text  //*[@data-test-id="question.title"][contains(text(), "${question_id}")]/following-sibling::form[contains(@action, "tender/questions")]/descendant::textarea  ${answer.data.answer}
    Click Element  //*[@data-test-id="question.title"][contains(text(), "${question_id}")]/../descendant::button[@name="answer_question_submit"]


Задати запитання на тендер
    [Arguments]  ${username}  ${tender_uaid}  ${question}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.questions"]
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Input Text  xpath=//input[@id="question-title"]  ${question.data.title}
    Input Text  xpath=//textarea[@id="question-description"]  ${question.data.description}
    Select From List By Value  //select[@id="question-questionof"]  tender
    Click Element  //button[@name="question_submit"]
    Wait Until Page Contains  ${question.data.title}


Задати запитання на предмет
    [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  xpath=//*[@data-test-id="sidebar.questions"]
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Input Text  xpath=//input[@id="question-title"]  ${question.data.title}
    Input Text  xpath=//textarea[@id="question-description"]  ${question.data.description}
    ${item_name}=  Get Text  xpath=//*[@id="question-questionof"]/descendant::*[contains(text(), "${item_id}")]
    Select From List By Label  xpath=//select[@id="question-questionof"]  ${item_name}
    Click Element  //button[@name="question_submit"]
    Wait Until Page Contains  ${question.data.title}


Подати цінову пропозицію
    [Arguments]   ${username}  ${tender_uaid}  ${bid}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  //input[@id="value-amount"]
    Convert Input Data To String  xpath=//input[@id="value-amount"]  ${bid.data.value.amount}
    Run Keyword And Ignore Error  Select Checkbox  xpath=//input[@id="rules_accept"]
    Wait Until Keyword Succeeds  30 x  5 s  Run Keywords
    ...  Run Keyword And Ignore Error  Click Element  //button[@id="submit_bid"]
    ...  AND  Wait Until Page Contains  очікує модерації
    Proposition  ${username}  ${bid.data.qualified}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Page Should Contain Element  //*[contains(@class, "label-success")][contains(text(), "опубліковано")]


Змінити цінову пропозицію
    [Arguments]  ${username}  ${tender_uaid}  ${field}  ${value}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  //input[@id="value-amount"]
    Run Keyword If  '${value}' != 'active'  Convert Input Data To String  xpath=//input[@id="value-amount"]  ${value}
    Refresh Page
    Capture Page Screenshot
    Wait Until Keyword Succeeds  30 x  1 s  Run Keywords
    ...  Click Element  //button[@id="submit_bid"]
    ...  AND  Refresh Page
    ...  AND  Page Should Contain Element  //*[contains(@class, "label-success")][contains(text(), "опубліковано")]
    Capture Page Screenshot


Скасувати цінову пропозицію
    [Arguments]  ${username}  ${tender_uaid}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll To And Click Element  //button[@name="delete_bids"]
    Wait Until Element Is Visible  //*[@class="bootbox-body"][contains(text(), "Видалити ставки")]
    Click Element  //button[contains(text(), "Застосувати")]
    Wait Until Element Is Not Visible  //*[@class="bootbox-body"][contains(text(), "Видалити ставки")]


Proposition
    [Arguments]  ${username}  ${status}
    ${url}=  Get Location
    Run Keyword If  ${status}
    ...  Go To  http://eauction.byustudio.in.ua/bids/send/${url.split('/')[-1]}?token=465
    ...  ELSE  Go To  http://eauction.byustudio.in.ua/bids/decline/${url.split('/')[-1]}?token=465
    Go To  ${USERS.users['${username}'].homepage}


Завантажити документ в ставку
    [Arguments]  ${username}  ${file_path}  ${tender_uaid}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll  //*[@action="/tender/fileupload"]/input
    Choose File  xpath=//*[@action="/tender/fileupload"]/input  ${file_path}
    Input Text  xpath=(//input[@class="file_name"])[last()]  ${file_path.split('/')[-1]}
    Select From List By Value  xpath=(//select[@class="select_document_type"])[last()]  qualificationDocuments


Змінити документ в ставці
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${docid}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll  //*[@action="/tender/fileupload"]/input
    Choose File  xpath=(//input[@name="FileUpload[file]"])[last()]  ${file_path}



Отримати інформацію із пропозиції
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Scroll  xpath=//input[@id="value-amount"]
    ${value}=  Get Value  xpath=//input[@id="value-amount"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Пошук тендера по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Switch Browser  my_alias
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    ${status}=  Run Keyword And Return Status  Wait Until Element Is Visible  xpath=//button[@data-dismiss="modal"]  5
    Run Keyword If  ${status}  Wait Until Keyword Succeeds  5 x  1 s  Click Element  xpath=//button[@data-dismiss="modal"]
    Scroll  xpath=//li[@class="dropdown"]/descendant::*[@class="dropdown-toggle"][contains(@href, "tenders")]
    Wait Until Element Is Visible  xpath=//li[@class="dropdown"]/descendant::*[@class="dropdown-toggle"][contains(@href, "tenders")]
    Click Element  xpath=//li[@class="dropdown"]/descendant::*[@class="dropdown-toggle"][contains(@href, "tenders")]
    Click Element  xpath=//*[@class="dropdown-menu"]/descendant::*[contains(@href, "/tenders/index")]
#    Wait Until Element Is Visible  xpath=//select[@id="attribute-select"]
#    Select From List By Value  xpath=//select[@id="attribute-select"]  tender_cbd_id
#    Input Text  xpath=//input[@id="attribute-input"]  ${tender_uaid}
#    Scroll To  xpath=//a[@id="search"]
#    Click Element  xpath=//a[@id="search"]
#    Wait Until Keyword Succeeds  20 x  1 s  JQuery Ajax Should Complete
#    Wait Until Element Is Visible  xpath=//div[@class="search-result_t"]/span[contains(text(), "${tender_uaid}")]
#    Scroll To  xpath=//*[@class="mk-btn mk-btn_default"][contains(@href, "/tender/view/")]
#    Wait Until Element Is Enabled  xpath=//*[@class="mk-btn mk-btn_default"][contains(@href, "/tender/view/")]
#    Click Element  xpath=//div[@class="search-result_t"]/span[contains(text(), "${tender_uaid}")]/../following-sibling::div[@class="search-result_ad"]/span[contains(text(), "майна замовника")]/ancestor::div[@class="search-result"]/descendant::a[contains(@href, "/tender/view/")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Шукати")]
    Click Element  xpath=//span[@data-target="#additional_filter"]
    Wait Until Element Is Visible  id=tenderssearch-tender_cbd_id
    Input Text  id=tenderssearch-tender_cbd_id  ${tender_uaid}
    Click Element  xpath=//button[contains(text(), "Шукати")]
    Wait Until Element Is Visible  xpath=//span[contains(text(), "майна замовника")]/../../descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//span[contains(text(), "майна замовника")]/../../descendant::div[contains(text(), "${tender_uaid}")]/../following-sibling::div/a
    ...  AND  Wait Until Element Is Not Visible  xpath=//span[contains(text(), "майна замовника")]/../../descendant::div[contains(text(), ${tender_uaid})]/../following-sibling::div/a
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="tenderID"]  20


Отримати інформацію із тендера
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  '${field}' == 'value.amount' or 'title' in '${field}'  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Refresh Page
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${value}=  Run Keyword If
    ...  '_ru' in '${field}'  Log To Console  ${red}\n\t\t\t ***** SITENAME не підтримує локалізацію російською мовою *****
    ...  ELSE IF  '_en' in '${field}'  Log To Console  ${red}\n\t\t\t ***** SITENAME не підтримує локалізацію англійською мовою *****
    ...  ELSE IF  '${field}' == 'title'  Get Text  xpath=//*[@data-test-id="title"]
    ...  ELSE IF  'awards' in '${field}'  Статус Аварду  ${username}  ${tender_uaid}  ${field}
    ...  ELSE IF  'status' in '${field}'  Отримати Статус  ${field}
    ...  ELSE IF  'cancellations' in '${field}'  Get Text  xpath=//*[@data-test-id="${field.replace('[0]','')}"]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//*[@data-test-id="description"]
    ...  ELSE IF  'tenderAttempts' in '${field}'  Get Element Attribute  xpath=//*[@data-test-id="tenderAttempts"]@data-test-value
    ...  ELSE IF  '${field}' == 'guarantee.amount'  Get Text  xpath=//*[@data-test-id="guarantee"]
    ...  ELSE IF  '${field}' == 'rectificationPeriod.endDate'  Get Text  xpath=(//*[@data-test-id="tenderPeriod.endDate"])[2]
    ...  ELSE IF  '${field}' == 'rectificationPeriod.invalidationDate'  Get Element Attribute  name=invalidationDate@value
#    ...  ELSE IF  'invalidationDate' in '${field}'  Get invalidationDate
    ...  ELSE  Get Text  xpath=//*[@data-test-id='${field.replace('auction', 'tender')}']

    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}


Get invalidationDate
    Wait Until Keyword Succeeds  20 x  20 s  Run Keywords
    ...  Click Element  xpath=//a[contains(@href, "tender/json")]
    ...  AND  Wait Until Element Is Visible  xpath=//div[contains(text(), "Час інвалідації")]
    ${value}=  Get Text  xpath=//div[contains(text(), "Час інвалідації")]
    ${value}=  convert_invalidation_date  ${value}
    [Return]  ${value}


Отримати кількість документів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  ${docs}=  Get Matching Xpath Count  xpath=//*[@data-test-id='document.title']
  ${docs}=  Convert To Integer  ${docs}
  [Return]  ${docs}


Отримати інформацію із предмету
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    ${red}=  Evaluate  "\\033[1;31m"
    Run Keyword If  'description' in '${field}'  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ${field}=  Set Variable If  '[' in '${field}'  ${field.split('[')[0]}${field.split(']')[1]}  ${field}
    ${value}=  Run Keyword If
    ...  '${field}' == 'classification.scheme'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::div[@data-test-id="item.classification.scheme"]
    ...  ELSE IF  '${field}' == 'unit.code'  Log To Console  ${red}\n\t\t\t Це поле не виводиться на eauction.byustudio.in.ua
    ...  ELSE IF  '${field}' == 'additionalClassifications.description'  Get Text  xpath=//*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[text()='PA01-7']/following-sibling::span
    ...  ELSE IF  '${field}' == 'contractPeriod.startDate'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[contains(text(), 'Дата початку договору оренди')]/following-sibling::*
    ...  ELSE IF  '${field}' == 'contractPeriod.endDate'  Get Text  //*[contains(text(),'${object_id}')]/ancestor::div[2]/descendant::*[contains(text(), 'Дата кiнця договору оренди')]/following-sibling::*
    ...  ELSE  Get Text  //div[contains(text(),'${object_id}')]/ancestor::div[contains(@class, "item-inf_txt")]/descendant::*[@data-test-id="item.${field}"]
    ${value}=  adapt_data  ${field}  ${value}
    [Return]  ${value}



Отримати кількість предметів в тендері
    [Arguments]  ${tender_owner}  ${tender_uaid}
    eauction.Пошук Тендера По Ідентифікатору  ${tender_owner}  ${tender_uaid}
    ${items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="item.description"]
    ${n_items}=  Convert To Integer  ${items}
    [Return]  ${n_items}


Отримати інформацію із документа
    [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
    ${value}=  Get Text  //a[contains(text(), '${doc_id}')]
    [Return]  ${value}


Отримати документ
    [Arguments]  ${username}  ${TENDER['TENDER_UAID']}  ${doc_id}
    ${file_name}=  Get Text  xpath=//a[contains(text(), '${doc_id}')]
    ${url}=  Get Element Attribute  xpath=//a[contains(text(), '${doc_id}')]@href
    download_file  ${url}  ${file_name}  ${OUTPUT_DIR}
    [Return]  ${file_name}


Отримати інформацію із запитання
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    eauction.Закрити Модалку
    Click Element  xpath=//*[@data-test-id="sidebar.questions"]
    Wait Until Element Is Not Visible  xpath=//*[@data-test-id="sidebar.questions"]
    eauction.Закрити Модалку
    ${value}=  Get Text  //*[contains(text(), '${object_id}')]/../descendant::*[@data-test-id='question.${field}']
    [Return]  ${value}


Отримати посилання на аукціон для глядача
    [Arguments]  ${viewer}  ${tender_uaid}  ${lot_id}=${Empty}
    eauction.Пошук Тендера По Ідентифікатору  ${viewer}  ${tender_uaid}
    ${link}=  Get Element Attribute  xpath=//*[contains(text(), "Посилання")]/../descendant::*[@class="h4"]/a@href
    [Return]  ${link}



Отримати посилання на аукціон для учасника
    [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
    Switch Browser  my_alias
    eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    Wait Until Element Is Visible  //a[@class="auction_seller_url"]
    ${current_url}=  Get Location
    Capture Page Screenshot
    Execute Javascript  window['url'] = null; $.get( "http://${host}/seller/tender/updatebid", { id: "${current_url.split("/")[-1]}"}, function(data){ window['url'] = data.data.participationUrl },'json');
    Wait Until Keyword Succeeds  20 x  1 s  JQuery Ajax Should Complete
    Capture Page Screenshot
    ${link}=  Execute Javascript  return window['url'];
    Log  ${link}
    [Return]  ${link}


Статус Аварду
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Run Keyword And Ignore Error  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    ...  AND  Run Keyword And Ignore Error  Click Element  xpath=//*[contains(text(), "Протокол розкриття пропозицiй")]
    ...  AND  Page Should Contain  Квалiфiкацiя учасникiв
    Page Should Not Contain Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    ${award}=  Convert To Integer  ${field[7:8]}
    Refresh Page
    Capture Page Screenshot
#    ${status}=  Get Text  xpath=(//div[@data-mtitle="Статус:"])[${award + 1}]
    ${status}=  Get Element Attribute  xpath=(//div[@data-mtitle="Статус:"]/input)[${award + 1}]@award_status
    [Return]  ${status}





Завантажити протокол аукціону в авард
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${award_index}
    Wait Until Keyword Succeeds  10 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    Run Keyword And Ignore Error  Click Element  xpath=//button[@data-dismiss="modal"]
    Wait Until Element Is Visible  //button[contains(text(), "Завантаження протоколу")]
    Click Element  xpath=//button[contains(text(), "Завантаження протоколу")]
    Wait Until Element Is Visible  //div[contains(text(), "Завантаження протоколу")]
    Choose File  //div[@id="verification-form-upload-file"]/descendant::input[@name="FileUpload[file][]"]  ${file_path}
    Wait Until Element Is Visible  //button[contains(@class, "delete-file-verification")]
    Click Element  //button[@name="protokol_ok"]
    Wait Until Element Is Not Visible  //button[@name="protokol_ok"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Not Contain Element  //button[@onclick="window.location.reload();"]


Підтвердити наявність протоколу аукціону
    [Arguments]  @{ARGUMENTS}
    eauction.Пошук Тендера По Ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    Wait Until Page Contains  Очікується підписання договору




Підтвердити постачальника
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    Wait Until Element Is Visible  //button[contains(text(), "Підтвердити отримання оплати")]
    Click Element  //button[contains(text(), "Підтвердити отримання оплати")]
    Wait Until Element Is Visible  //div[contains(text(), "Оплата буде підтверджена")]
    Click Element  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Element Is Not Visible  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  xpath=//button[contains(text(), "Контракт")]


Скасування рішення кваліфікаційної комісії
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    Wait Until Element Is Visible  //button[contains(text(), "Забрати гарантійний внесок")]
    Click Element  //button[contains(text(), "Забрати гарантійний внесок")]
    Wait Until Element Is Visible  //div[contains(text(), "Подальшу участь буде скасовано")]
    Click Element  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Element Is Not Visible  //*[@class="modal-footer"]/button[contains(text(), "Застосувати")]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Contains  Рiшення скасовано


Завантажити угоду до тендера
    [Arguments]  ${username}  ${tender_uaid}  ${number}  ${file_path}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    Wait Until Element Is Visible  xpath=//button[contains(text(), "Контракт")]
    Click Element  xpath=//button[contains(text(), "Контракт")]
    Wait Until Element Is Visible  //div[contains(@class, "h2")][contains(text(), "Контракт")]
    Choose File  //div[@id="uploadcontract"]/descendant::input  ${file_path}
    Input Text  //input[@id="contract-contractnumber"]  1234567890
    Click Element  //button[@id="contract-fill-data"]
    Wait Until Element Is Not Visible  //button[@id="contract-fill-data"]
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  //button[@id="contract-activate"]




Підтвердити підписання контракту
    [Arguments]  ${username}  ${tender_uaid}  ${number}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    Click Element  //button[@id="contract-activate"]
    Confirm Action
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  Reload Page
    ...  AND  Page Should Contain Element  //div[@data-test-id="status"][contains(text(), "Продаж завершений")]


Дискваліфікувати постачальника
    [Arguments]  ${username}  ${tender_uaid}  ${number}  ${description}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    ${file}=  my_file_path
    Wait Until Element Is Visible  //button[@data-toggle="modal"][contains(text(), "Дисквалiфiкувати")]
    Click Element  //button[@data-toggle="modal"][contains(text(), "Дисквалiфiкувати")]
    Wait Until Element Is Visible  //div[contains(@class, "h2")][contains(text(), "Дискваліфікація")]
    Wait Until Element Is Visible  xpath=(//*[@name="Award[cause][]"])[1]/..
    Click Element  xpath=(//*[@name="Award[cause][]"])[1]/..
    Choose File  //div[@id="disqualification-form-upload-file"]/descendant::input[@name="FileUpload[file][]"]  ${file}
    Input Text  //textarea[@id="award-description"]  ${description}
    Click Element  //button[@id="disqualification"]
    Wait Until Element Is Visible  //div[contains(@class,'alert-success')]


Отримати кількість авардів в тендері
    [Arguments]  ${username}  ${tender_uaid}
    Run Keyword And Ignore Error  eauction.Перейти На Страницу Квалификации  ${username}  ${tender_uaid}
    ${awards}=  Get Matching Xpath Count  xpath=//div[contains(@class, "qtable")]/descendant::div[@data-mtitle="№"]
    ${n_awards}=  Convert To Integer  ${awards}
    [Return]  ${n_awards}



Scroll
    [Arguments]  ${locator}
    Execute JavaScript    window.scrollTo(0,0)


Scroll To
    [Arguments]  ${locator}
    ${y}=  Get Vertical Position  ${locator}
    Execute JavaScript    window.scrollTo(0,${y-100})


Scroll To And Click Element
    [Arguments]  ${locator}
    ${y}=  Get Vertical Position  ${locator}
    Execute JavaScript    window.scrollTo(0,${y-100})
    Click Element  ${locator}


Отримати Статус
    [Arguments]  ${field}
    Reload Page
    ${status}=  Run Keyword If
    ...  'cancellations' in '${field}'  Get Element Attribute  //*[contains(text(), "Причина скасування")]@data-test-id-cancellation-status
    ...  ELSE  Get Text  xpath=//*[@data-test-id="status"]
    ${status}=  adapt_data  ${field}  ${status}
    [Return]  ${status}


Закрити Модалку
    ${status}=  Run Keyword And Return Status  Wait Until Element Is Visible  xpath=//button[@data-dismiss="modal"]  5
    Run Keyword If  ${status}  Wait Until Keyword Succeeds  5 x  1 s  Run Keywords
    ...  Click Element  xpath=//button[@data-dismiss="modal"]
    ...  AND  Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]


Adapt And Select By Value
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    ${value}=  adapted_dictionary  ${value}
    Select From List By Value  ${locator}  ${value}


Convert Input Data To String
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Input Text  ${locator}  ${value}


Get Data
    [Arguments]  ${tender_data}
    [Return]  ${tender_data.data}


Close Sidebar
    Click Element  xpath=//*[@id="slidePanelToggle"]


Wait For Document Upload
    Wait Until Keyword Succeeds  30 x  5 s  Run Keywords
    ...  Refresh Page
    ...  AND  Run Keyword And Ignore Error  Click Element  xpath=//*[@data-test-id="sidebar.edit"]
    ...  AND  Wait Until Element Is Visible  xpath=//*[@id="auction-form"]

Select From List By Converted Value
    [Arguments]  ${locator}  ${value}
    ${converted_value}=  Convert To String  ${value}
    Select From List By Value  ${locator}  ${converted_value}



Перейти На Страницу Квалификации
    [Arguments]  ${username}  ${tender_uaid}
    Wait Until Keyword Succeeds  30 x  20 s  Run Keywords
    ...  eauction.Пошук Тендера По Ідентифікатору  ${username}  ${tender_uaid}
    ...  AND  Click Element  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]
    ...  AND  Wait Until Element Is Not Visible  xpath=//*[contains(text(), "Таблиця квалiфiкацiї")]


Compare Number Elements
    [Arguments]  ${n_items}
    ${items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="item.description"]
    ${actual_items}=  Convert To Integer  ${items}
    Should Be Equal  ${actual_items}  ${n_items + 1}

JQuery Ajax Should Complete
    ${active}=  Execute Javascript  return jQuery.active
    Should Be Equal  "${active}"  "0"

Refresh Page
  Click Element  xpath=//a[contains(@href, "tender/json")]
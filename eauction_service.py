#!/usr/bin/python
# -*- coding: utf-8 -*-
from datetime import datetime
import pytz
import urllib
import os


tz = str(datetime.now(pytz.timezone('Europe/Kiev')))[26:]


def prepare_tender_data_asset(tender_data):
    tender_data['data']['assetCustodian']['identifier']['id'] = u'01010122'
    tender_data['data']['assetCustodian']['name'] = u'ТОВ Орган Приватизации'
    tender_data['data']['assetCustodian']['identifier']['legalName'] = u'ТОВ Орган Приватизации'
    tender_data['data']['assetCustodian']['contactPoint']['name'] = u'Гоголь Микола Васильович'
    tender_data['data']['assetCustodian']['contactPoint']['telephone'] = u'+38(101)010-10-10'
    tender_data['data']['assetCustodian']['contactPoint']['email'] = u'primatization@aditus.info'
    return tender_data


# def adapt_lot_creation_data(tender_data):
#     tender_data['data']['decisions'][0]['decisionDate'] = u"{}T00:00:00.000000+03:00".format(tender_data['data']['decisions'][0]['decisionDate'].split("T")[0])
#     return tender_data


def prepare_tender_data(role, data):
    if role == 'tender_owner' and 'procuringEntity' in data['data']:
        data['data']['procuringEntity']['name'] = u'Тестовый "ЗАКАЗЧИК" 2'
        for item in data['data']['items']:
            item['address']['region'] = item['address']['region'].replace(u' область', u'')
    elif role == 'tender_owner' and 'assetCustodian' in data['data']:
        data = prepare_tender_data_asset(data)
    # else:
    #     data = adapt_lot_creation_data(data)
    return data


def convert_date_from_item(date):
    date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%d')
    return '{}T00:00:00{}'.format(date, tz)


def convert_date(date):
    if '.' in date:
        date = datetime.strptime(date, '%d.%m.%Y %H:%M:%S').strftime('%Y-%m-%dT%H:%M:%S.%f')
    else:
        date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%dT%H:%M:%S.%f')
    return '{}{}'.format(date, tz)


def convert_date_for_item(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S{}'.format(tz)).strftime('%d/%m/%Y %H:%M')
    return '{}'.format(date)


def convert_date_for_auction(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y %H:%M:%S')
    return '{}'.format(date)


def convert_date_from_decision(date):
    date = datetime.strptime(date, '%d/%m/%Y'.format(tz)).strftime('%Y-%m-%dT%H:%M:%S.%f')
    return '{}{}'.format(date, tz)


def convert_date_for_decision(date):
    date = datetime.strptime(date, '%Y-%m-%d'.format(tz)).strftime('%d/%m/%Y')
    return '{}'.format(date)


def adapted_dictionary(value):
    return{
        # u"з урахуванням ПДВ": True,
        # u"без урахування ПДВ": False,
        # u"True": "1",
        # u"False": "0",
        # u"Оголошення аукціону з Оренди": "dgfOtherAssets",
        u'Класифікація згідно CAV': 'CAV',
        u'Класифікація згідно CAV-PS': 'CAV-PS',
        u'Класифікація згідно CPV': 'CPV',
        # u'Очiкування пропозицiй': 'active.tendering',
        # u'Перiод уточнень': 'active.enquires',
        u'Аукцiон': 'active.auction',
        # u'Квалiфiкацiя переможця': 'active.qualification',
        u'Торги не відбулися': 'unsuccessful',
        u'Продаж завершений': 'complete',
        u'Торги скасовано': 'cancelled',
        # u'Торги були відмінені.': 'active',
        u'об’єкт реєструється': u'registering',
        u'об’єкт зареєстровано': u'complete',
        u'Опубліковано': u'pending',
        u'Актив завершено': u'complete',
        u'Публікація інформаційного повідомлення': u'composing',
        u'Перевірка доступності об’єкту': u'verification',
        u'lot.status.pending.deleted': u'pending.deleted',
        u'Лот видалено': u'deleted',
        u'Інформація': u'informationDetails',
        u'Заплановано': u'scheduled'
    }.get(value, value)


def adapt_data(field, value):
    if field == 'tenderAttempts':
        value = int(value)
    elif field == 'value.amount':
        value = float(value)
    elif field == 'minimalStep.amount':
        value = float(value.split(' ')[0])
    elif field == 'guarantee.amount':
        value = float(value.split(' ')[0])
    elif field == 'quantity':
        value = float(value.replace(',', '.'))
    elif field == 'minNumberOfQualifiedBids':
        value = int(value)
    elif 'contractPeriod' in field:
        value = convert_date_from_item(value)
    elif 'tenderPeriod' in field or 'auctionPeriod' in field or 'rectificationPeriod' in field and 'invalidationDate' not in field:
        value = convert_date(value)
    else:
        value = adapted_dictionary(value)
    return value


def adapt_asset_data(field, value):
    if 'date' in field:
        value = convert_date(value)
    elif 'decisionDate' in field:
        value = convert_date_from_decision(value.split(' ')[0])
    elif 'documentType' in field:
        value = adapted_dictionary(value.split(' ')[0])
    elif 'rectificationPeriod.endDate' in field:
        value = convert_date(value)
    elif 'documentType' in field:
        value = value
    else:
        value = adapted_dictionary(value)
    return value


def adapt_lot_data(field, value):
    if 'amount' in field:
        value = float(value.split(' ')[0])
    # elif 'minimalStep.amount' in field:
    #     value = float(value.split(' ')[0])
    # elif 'guarantee.amount' in field:
    #     value = float(value.split(' ')[0])
    elif 'tenderingDuration' in field:
        value = value.split(' ')[0]
        if 'M' in value:
            value = 'P{}'.format(value)
        else:
            value = 'P{}D'.format(value)
    elif 'auctionPeriod.startDate' in field:
        value = convert_date(value)
    elif 'classification.id' in field:
        value = value.split(' - ')[0]
    elif 'unit.name' in field:
        value = ' '.join(value.split(' ')[1:])
    elif 'quantity' in field:
        value = float(value.split(' ')[0])
    elif 'registrationFee.amount' in field:
        value = float(value.split(' ')[0])
    elif 'tenderAttempts' in field:
        value = int(value)
    else:
        value = adapted_dictionary(value)
    return value


def convert_period_date(date):
    if date == 'P1M':
        date = '30'
    else:
        date = '30'
    return date


def convert_invalidation_date(data):
    return convert_date(' '.join(data.split(' ')[2:]).strip())


def download_file(url, filename, folder):
    urllib.urlretrieve(url, ('{}/{}'.format(folder, filename)))


def my_file_path():
    return os.path.join(os.getcwd(), 'src', 'robot_tests.broker.eauction', 'Doc.pdf')

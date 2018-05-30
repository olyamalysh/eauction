#!/usr/bin/python
# -*- coding: utf-8 -*-
from datetime import datetime
import pytz
import urllib
import os


tz = str(datetime.now(pytz.timezone('Europe/Kiev')))[26:]


def prepare_tender_data(role, data):
    if role == 'tender_owner':
        data['data']['procuringEntity']['name'] = u'Тестовый "ЗАКАЗЧИК" 2'
        for item in data['data']['items']:
            item['address']['region'] = item['address']['region'].replace(u' область', u'')
    return data


def convert_date_from_item(date):
    date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%d')
    return '{}T00:00:00{}'.format(date, tz)


def convert_date(date):
    date = datetime.strptime(date, '%d/%m/%Y %H:%M:%S').strftime('%Y-%m-%dT%H:%M:%S.%f')
    return '{}{}'.format(date, tz)


def convert_date_for_item(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S{}'.format(tz)).strftime('%d/%m/%Y %H:%M')
    return '{}'.format(date)


def convert_date_for_auction(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y %H:%M')
    return '{}'.format(date)


def convert_date_for_decision(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y')
    return '{}'.format(date)


def adapted_dictionary(value):
    return{
        u"з урахуванням ПДВ": True,
        u"без урахування ПДВ": False,
        u"True": "1",
        u"False": "0",
        u"Оголошення аукціону з Оренди": "dgfOtherAssets",
        u'Класифікація згідно CAV': 'CAV',
        u'Класифікація згідно CAV-PS': 'CAV-PS',
        u'Класифікація згідно CPV': 'CPV',
        u'Очiкування пропозицiй': 'active.tendering',
        u'Перiод уточнень': 'active.enquires',
        u'Аукцiон': 'active.auction',
        u'Квалiфiкацiя переможця': 'active.qualification',
        u'Торги не відбулися': 'unsuccessful',
        u'Продаж завершений': 'complete',
        u'Торги скасовано': 'cancelled',
        u'Торги були відмінені.': 'active',
        # u'Очікується підписання договору': 'pending.payment',
        # u'Очікується протокол': 'pending.verification',
        # u'На черзі': 'pending.waiting',
        # u'Рiшення скасовано': 'cancelled',
        # u'Оплачено, очікується підписання договору': 'active',
        # u'Дискваліфіковано': 'unsuccessful'
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
    value = adapted_dictionary(value)
    return value


def convert_invalidation_date(data):
    return convert_date(' '.join(data.split(' ')[2:]).strip())


def download_file(url, filename, folder):
    urllib.urlretrieve(url, ('{}/{}'.format(folder, filename)))


def my_file_path():
    return os.path.join(os.getcwd(), 'src', 'robot_tests.broker.eauction', 'Doc.pdf')

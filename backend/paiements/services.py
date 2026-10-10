import hashlib
import hmac
import requests
from django.conf import settings


class CinetPayException(Exception):
    pass


class CinetPayService:
    """Service integration CinetPay pour paiements Mobile Money CI."""

    def __init__(self):
        self.api_key = settings.CINETPAY_API_KEY
        self.site_id = settings.CINETPAY_SITE_ID
        self.secret_key = settings.CINETPAY_SECRET_KEY
        self.base_url = settings.CINETPAY_BASE_URL

    def initier_paiement(self, reference, montant, description, telephone, methode, metadata=None):
        import json
        payload = {
            'apikey': self.api_key, 'site_id': self.site_id,
            'transaction_id': reference, 'amount': str(montant),
            'currency': 'XOF', 'description': description,
            'notify_url': f'{settings.FRONTEND_URL}/api/v1/paiements/webhook/',
            'return_url': f'{settings.FRONTEND_URL}/reservation/succes',
            'channels': self._get_channel(methode), 'lang': 'FR',
            'metadata': json.dumps(metadata or {}),
        }
        if telephone:
            payload['customer_phone_number'] = self._normaliser_telephone(telephone)
            payload['customer_name'] = 'TamBour Client'
            payload['customer_email'] = 'client@tambour.ci'
        try:
            response = requests.post(f'{self.base_url}/payment', json=payload, timeout=30)
            response.raise_for_status()
            data = response.json()
            if data.get('code') not in ['201', 201]:
                raise CinetPayException(data.get('message', 'Erreur CinetPay inconnue'))
            return {
                'transaction_id': data['data']['transaction_id'],
                'url_paiement': data['data'].get('payment_url', ''),
                'operateur_reference': data['data'].get('ref', ''),
                'raw': data,
            }
        except requests.RequestException as e:
            raise CinetPayException(f'Erreur reseau CinetPay : {str(e)}')

    def verifier_paiement(self, transaction_id):
        payload = {'apikey': self.api_key, 'site_id': self.site_id, 'transaction_id': transaction_id}
        try:
            response = requests.post(f'{self.base_url}/payment/check', json=payload, timeout=30)
            response.raise_for_status()
            data = response.json()
            return {'statut': data['data']['status'], 'montant': data['data'].get('amount'), 'raw': data}
        except requests.RequestException as e:
            raise CinetPayException(f'Erreur verification : {str(e)}')

    def verifier_signature_webhook(self, payload, signature_recue):
        message = ''.join(str(payload.get(k, '')) for k in [
            'cpm_site_id', 'cpm_trans_id', 'cpm_trans_date', 'cpm_amount', 'cpm_currency',
            'signature', 'payment_method', 'cel_phone_num', 'cpm_phone_prefixe',
            'cpm_language', 'cpm_version', 'cpm_payment_config', 'cpm_page_action',
            'cpm_custom', 'cpm_designation', 'cpm_error_message'])
        expected = hmac.new(self.secret_key.encode(), message.encode(), hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature_recue)

    def _get_channel(self, methode):
        return {
            'mtn_momo': 'MOBILE_MONEY',
            'orange_money': 'MOBILE_MONEY',
            'wave': 'WAVE',
            'carte': 'CREDIT_CARD',
        }.get(methode, 'ALL')

    def _normaliser_telephone(self, telephone):
        tel = telephone.replace(' ', '').replace('-', '')
        if tel.startswith('00225'):
            return tel[5:]
        if tel.startswith('+225'):
            return tel[4:]
        if tel.startswith('225'):
            return tel[3:]
        return tel

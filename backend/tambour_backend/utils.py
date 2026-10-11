from rest_framework.views import exception_handler
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        response.data = {
            'success': False,
            'message': _get_message(response.data),
            'errors': response.data,
            'status_code': response.status_code,
        }
    return response


def _get_message(data):
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, list) and value:
                return str(value[0])
            if isinstance(value, str):
                return value
    if isinstance(data, list) and data:
        return str(data[0])
    return 'Une erreur est survenue.'


def success_response(data=None, message='Succès', status_code=200):
    return Response({'success': True, 'message': message, 'data': data}, status=status_code)


def error_response(message='Erreur', errors=None, status_code=400):
    return Response({'success': False, 'message': message, 'errors': errors or {}}, status=status_code)


class EnveloppePagination(PageNumberPagination):
    """Pagination par défaut : même enveloppe { success, data } que le reste de l'API."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 500

    def get_paginated_response(self, data):
        return success_response(data={
            'count': self.page.paginator.count,
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'results': data,
        })


class EnveloppeMixin:
    """Pour les ModelViewSet : enveloppe aussi détail / création / modification dans { success, data }."""

    def finalize_response(self, request, response, *args, **kwargs):
        if isinstance(response, Response) and 200 <= response.status_code < 300 and response.status_code != 204:
            d = response.data
            if not (isinstance(d, dict) and 'success' in d):
                response.data = {'success': True, 'message': 'Succès', 'data': d}
        return super().finalize_response(request, response, *args, **kwargs)

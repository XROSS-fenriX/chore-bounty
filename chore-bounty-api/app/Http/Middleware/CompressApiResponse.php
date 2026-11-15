<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

class CompressApiResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        if ($response instanceof BinaryFileResponse || $response instanceof StreamedResponse) {
            return $response;
        }

        if ($response->headers->has('Content-Encoding')) {
            return $response;
        }

        $content = $response->getContent();
        if ($content === false || $content === '') {
            return $response;
        }

        $contentType = strtolower((string) $response->headers->get('Content-Type', ''));
        $isCompressible = $contentType === ''
            || str_contains($contentType, 'json')
            || str_starts_with($contentType, 'text/');

        $acceptsGzip = stripos((string) $request->header('Accept-Encoding', ''), 'gzip') !== false;

        if ($isCompressible && $acceptsGzip && function_exists('gzencode') && strlen($content) >= 512) {
            $compressed = gzencode($content, 6);
            if ($compressed !== false) {
                $response->setContent($compressed);
                $response->headers->set('Content-Encoding', 'gzip');
                $response->headers->set('Content-Length', (string) strlen($compressed));

                $vary = array_filter(array_map('trim', explode(',', (string) $response->headers->get('Vary', ''))));
                if (! in_array('Accept-Encoding', $vary, true)) {
                    $vary[] = 'Accept-Encoding';
                    $response->headers->set('Vary', implode(', ', $vary));
                }

                return $response;
            }
        }

        if (! $response->headers->has('Content-Length')) {
            $response->headers->set('Content-Length', (string) strlen($content));
        }

        return $response;
    }
}

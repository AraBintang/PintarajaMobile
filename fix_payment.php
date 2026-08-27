<?php
\ = 'C:\Users\ASUS\.gemini\antigravity\scratch\pintaraja_web\app\Http\Controllers\PaymentController.php';
\ = file_get_contents(\);

// Find the block starting with \ = [ and ending with \ = \['checkout_url'] ?? null;
\ = '/(\ = \[.*\ = \\[\'checkout_url\'\] \?\? null;)/is';

if (preg_match(\, \, \)) {
    \ = \[1];
    
    \ = <<<EOT
        \ = null;
        \ = null;
        \ = [];
        \ = time() + 86400;
        \ = '';

        if (strtolower(\['channel']) === 'cards') {
            \ = config('services.xendit.secret_key');
            \ = Http::withBasicAuth(\, '')
                ->post('https://api.xendit.co/v2/invoices', [
                    'external_id' => \,
                    'amount' => \,
                    'payer_email' => \->M_UserEmail,
                    'description' => \['item'],
                    'customer' => [
                        'given_names' => \->M_UserFullName,
                        'email' => \->M_UserEmail,
                        'mobile_number' => \['phone']
                    ],
                    'payment_methods' => ['CREDIT_CARD']
                ]);

            if (\->failed()) {
                \Log::error('Xendit API Error', ['status' => \->status(), 'body' => \->body()]);
                return response()->json(['error' => 'Failed while creating payment'], 500);
            }
            
            \ = \->json();
            \ = \['invoice_url'];
            \ = \['id'];
            \ = strtotime(\['expiry_date'] ?? '+1 day');
        } else {
\
            \ = \['reference'];
            \ = \['expired_time'] ?? (time() + 86400);
        }
EOT;
    
    \ = str_replace(\, \, \);
    
    // Fix Transaction::create arguments
    \ = str_replace("'T_TransactionIdResult' => \['reference']", "'T_TransactionIdResult' => \", \);
    \ = str_replace("'T_TransactionExpired' => \['expired_time'] ?? (time() + 86400)", "'T_TransactionExpired' => \", \);
    
    file_put_contents(\, \);
    echo "SUCCESS\n";
} else {
    echo "NOT FOUND\n";
}

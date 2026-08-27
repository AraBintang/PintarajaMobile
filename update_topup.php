<?php
\ = 'C:/Users/ASUS/.gemini/antigravity/scratch/pintaraja_web/app/Http/Controllers/PaymentController.php';
\ = file_get_contents(\);

\ = <<<'EOT'
         = [
            'method' => ['channel'],
            'merchant_ref' => ,
            'amount' => ,
            'customer_name' => ->M_UserFullName,
            'customer_email' => ->M_UserEmail,
            'customer_phone' => ['phone'],
            'order_items' => [[
                'name' => 'Topup Koin - ' . ,
                'price' => ,
                'quantity' => 1,
            ]],
            'signature' => hash_hmac('sha256',  .  . , ),
        ];

         = app()->environment('local', 'development');
         = 
            ? 'https://tripay.co.id/api-sandbox/transaction/create'
            : 'https://tripay.co.id/api/transaction/create';

         = Http::withHeaders([
            'Authorization' => 'Bearer ' . ,
        ])->post(, );

        if (->failed()) {
            \Log::error('Tripay API Error (Topup)', [
                'status' => ->status(),
                'body' => ->body(),
            ]);
            return response()->json(['error' => 'Failed while creating payment'], 500);
        }

         = ['data'];
         = strtolower(['channel']) === 'qris2' || strtolower(['method']) === 'qris';

         = null;
        if () {
             = ['qr_url'] ?? null;
        } elseif (!empty(['pay_code'])) {
             = ['pay_code'];
        } elseif (!empty(['pay_url'])) {
             = ['pay_url'];
        }

         = ['instructions'] ?? [];
         = ['checkout_url'] ?? null;

         = Transaction::create([
            'T_TransactionM_UserID' => ->M_UserID,
            'T_TransactionM_PlanID' => 0,
            'T_TransactionType' => 'topup',
            'T_TransactionIdResult' => ['reference'],
            'T_TransactionIdRefrence' => ['merchant_ref'],
            'T_TransactionQR' => ,
            'T_TransactionItem' => 'Topup Koin - ' . ,
            'T_TransactionAmount' => ,
            'T_TransactionStatus' => 0,
            'T_TransactionMethod' => ['method'],
            'T_TransactionExpired' => ['expired_time'] ?? (time() + 86400),
            'T_TransactionChannel' => ['channel'],
            'T_TransactionStep' => json_encode(),
            'T_TransactionCheckoutURL' => ,
        ]);
EOT;

\ = <<<'EOT'
         = null;
         = null;
         = [];
         = time() + 86400;
         = '';

        if (strtolower(['channel']) === 'visa' || strtolower(['channel']) === 'cards') {
             = config('services.xendit.secret_key');
             = Http::withBasicAuth(, '')
                ->post('https://api.xendit.co/v2/invoices', [
                    'external_id' => ,
                    'amount' => ,
                    'payer_email' => ->M_UserEmail,
                    'description' => 'Topup Koin - ' . ,
                    'customer' => [
                        'given_names' => ->M_UserFullName,
                        'email' => ->M_UserEmail,
                        'mobile_number' => ['phone']
                    ],
                    'payment_methods' => ['CREDIT_CARD']
                ]);

            if (->failed()) {
                \Log::error('Xendit API Error', ['status' => ->status(), 'body' => ->body()]);
                return response()->json(['error' => 'Failed while creating payment'], 500);
            }
            
             = ->json();
             = ['invoice_url'];
             = ['id'];
             = strtotime(['expiry_date'] ?? '+1 day');
        } else {
             = [
                'method' => ['channel'],
                'merchant_ref' => ,
                'amount' => ,
                'customer_name' => ->M_UserFullName,
                'customer_email' => ->M_UserEmail,
                'customer_phone' => ['phone'],
                'order_items' => [[
                    'name' => 'Topup Koin - ' . ,
                    'price' => ,
                    'quantity' => 1,
                ]],
                'signature' => hash_hmac('sha256',  .  . , ),
            ];

             = app()->environment('local', 'development');
             = 
                ? 'https://tripay.co.id/api-sandbox/transaction/create'
                : 'https://tripay.co.id/api/transaction/create';

             = Http::withHeaders([
                'Authorization' => 'Bearer ' . ,
            ])->post(, );

            if (->failed()) {
                \Log::error('Tripay API Error (Topup)', [
                    'status' => ->status(),
                    'body' => ->body(),
                ]);
                return response()->json(['error' => 'Failed while creating payment'], 500);
            }

             = ['data'];
             = strtolower(['channel']) === 'qris2' || strtolower(['method']) === 'qris';

            if () {
                 = ['qr_url'] ?? null;
            } elseif (!empty(['pay_code'])) {
                 = ['pay_code'];
            } elseif (!empty(['pay_url'])) {
                 = ['pay_url'];
            }

             = ['instructions'] ?? [];
             = ['checkout_url'] ?? null;
             = ['reference'];
             = ['expired_time'] ?? (time() + 86400);
        }

         = Transaction::create([
            'T_TransactionM_UserID' => ->M_UserID,
            'T_TransactionM_PlanID' => 0,
            'T_TransactionType' => 'topup',
            'T_TransactionIdResult' => ,
            'T_TransactionIdRefrence' => ,
            'T_TransactionQR' => ,
            'T_TransactionItem' => 'Topup Koin - ' . ,
            'T_TransactionAmount' => ,
            'T_TransactionStatus' => 0,
            'T_TransactionMethod' => ['method'],
            'T_TransactionExpired' => ,
            'T_TransactionChannel' => ['channel'],
            'T_TransactionStep' => json_encode(),
            'T_TransactionCheckoutURL' => ,
        ]);
EOT;

\ = str_replace(\, \, \);
file_put_contents(\, \);

echo "OK";
?>

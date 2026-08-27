with open(r'C:\Users\ASUS\.gemini\antigravity\scratch\pintaraja_web\app\Http\Controllers\PaymentController.php', 'r', encoding='utf-8') as f:
    content = f.read()

find_str = """         = [
            'method' => ['channel'],
            'merchant_ref' => ,
            'amount' => ,
            'customer_name' => ->M_UserFullName,
            'customer_email' => ->M_UserEmail,
            'customer_phone' => ['phone'],
            'order_items' => [[
                'name' => ['item'],
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
            \Log::error('Tripay API Error', [
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
         = ['checkout_url'] ?? null;"""

replace_str = """         = null;
         = null;
         = [];
         = time() + 86400;
         = '';

        if (strtolower(['channel']) === 'cards' || strtolower(['channel']) === 'credit_card') {
             = config('services.xendit.secret_key');
             = Http::withBasicAuth(, '')
                ->post('https://api.xendit.co/v2/invoices', [
                    'external_id' => ,
                    'amount' => ,
                    'payer_email' => ->M_UserEmail,
                    'description' => ['item'],
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
""" + find_str + """
             = ['reference'];
             = ['expired_time'] ?? (time() + 86400);
        }"""

new_content = content.replace(find_str, replace_str)
new_content = new_content.replace("'T_TransactionIdResult' => ['reference']", "'T_TransactionIdResult' => ")
new_content = new_content.replace("'T_TransactionExpired' => ['expired_time'] ?? (time() + 86400)", "'T_TransactionExpired' => ")

with open(r'C:\Users\ASUS\.gemini\antigravity\scratch\pintaraja_web\app\Http\Controllers\PaymentController.php', 'w', encoding='utf-8') as f:
    f.write(new_content)

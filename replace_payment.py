import re

with open(r'C:\Users\ASUS\.gemini\antigravity\scratch\pintaraja_web\app\Http\Controllers\PaymentController.php', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace store logic
store_search = r'''(\ = \[
\s*'method' => \\['channel'\],.*?\ = strtolower\(\\['channel'\]\) === 'qris2' \|\| strtolower\(\\['method'\]\) === 'qris';

\s*\ = null;
\s*if \(\\) \{
\s*\ = \\['qr_url'\] \?\? null;
\s*\} elseif \(!empty\(\\['pay_code'\]\)\) \{
\s*\ = \\['pay_code'\];
\s*\} elseif \(!empty\(\\['pay_url'\]\)\) \{
\s*\ = \\['pay_url'\];
\s*\}

\s*\ = \\['instructions'\] \?\? \[\];
\s*\ = \\['checkout_url'\] \?\? null;)'''

store_replace = r'''
         = null;
         = null;
         = [];
         = time() + 86400;
         = '';

        if (strtolower(['channel']) === 'cards') {
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
            \1
             = ['reference'];
             = ['expired_time'] ?? (time() + 86400);
        }
'''

new_content = re.sub(store_search, store_replace, content, flags=re.DOTALL)

# Now fix the Transaction::create call for store
tx_store_search = r'''('T_TransactionIdResult' => )\\['reference'\],'''
tx_store_replace = r'''\1,'''
new_content = re.sub(tx_store_search, tx_store_replace, new_content)

tx_expired_search = r'''('T_TransactionExpired' => )\\['expired_time'\] \?\? \(time\(\) \+ 86400\),'''
tx_expired_replace = r'''\1,'''
new_content = re.sub(tx_expired_search, tx_expired_replace, new_content)

with open(r'C:\Users\ASUS\.gemini\antigravity\scratch\pintaraja_web\app\Http\Controllers\PaymentController.php', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done python script")

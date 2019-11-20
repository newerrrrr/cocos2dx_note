<?php
namespace App\Common;

use PhalApi\Crypt;

/**
 * AesCrypt aes 对称加密算法
 *
 */

class AesCrypt implements Crypt
{

    protected $method;

    public function __construct($method = 'AES-256-CBC')
    {
        $this->method = $method;
    }

    public function encrypt($data, $key)
    {

        if (!is_string($data)) {
            $data_str = json_encode($data);
        } else {
            $data_str = $data;
        }

        $iv = pack("c16", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
        $length = strlen($data_str);

        // var_dump($data_str, $iv, $length, $this->method, $key);

        // 填充结尾的空字符串，补足长度未 32 的倍数
        $len = 32;
        $f_len = ceil($length / $len);
        $n_len = $len * $f_len - $length;
        for ($i = 0; $i < $n_len; $i++) {
            $data_str .= pack("c1", 0x00);
        }
        // var_dump($len, $length, $f_len, $n_len, $data_str);

        // $encrypted = \mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $data_str, MCRYPT_MODE_CBC, $iv);
        $encrypted = openssl_encrypt($data_str, $this->method, $key, OPENSSL_ZERO_PADDING, $iv);

        // var_dump($encrypted, base64_encode($encrypted));

        // $re = $encrypted;
        $re = pack('N1', $length) . base64_decode($encrypted);
        // $re = pack('N1', $length) . $encrypted;
        $re = base64_encode($re);

        // var_dump($re, $this->decrypt($re, $key));

        // 是否需要 url encode
        if (isset($_SESSION['request_data_urlencode']) and $_SESSION['request_data_urlencode']) {
            $re = urlencode($re);
        }

        return $re;

        // return base64_encode(openssl_encrypt($data_str, $this->method, $key, OPENSSL_RAW_DATA, $this->iv));
    }

    public function decrypt($e_data, $key)
    {
        // 检查标记有没有 url encode
        $_SESSION['request_data_urlencode'] = false;
        if (strpos($e_data, '%') !== false) {
            $_SESSION['request_data_urlencode'] = true;
            $e_data = urldecode($e_data);
        }

        // 安装老版库进行解密
        $e_data = base64_decode($e_data);
        $data = unpack("N1length", $e_data);
        $content = substr($e_data, 4, strlen($e_data) - 4);
        $length = $data['length'];
        // $data_str = \mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $key, $content, MCRYPT_MODE_CBC, $this->iv);

        $data_str = openssl_decrypt(base64_encode($content), $this->method, $key, OPENSSL_ZERO_PADDING);
        $data_str = trim($data_str);

        // 新版的解密方式无法正常执行，只能换老款
        // $data_str = openssl_decrypt($data, $this->method, $key, OPENSSL_RAW_DATA, $this->iv);
        $data = @json_decode($data_str, true);
        if (empty($data)) {
            $data = $data_str;
        }
        return $data;
    }
}

/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require('hardhat-abi-exporter'); // 新增插件，用于前端开发

module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      chainId: 31337, // 本地节点默认链 ID
      accounts: [
        {
          privateKey: "0x4dac35d4a738c743648f9fd2d2fefe542d5a70b813bd9106b6a3a8f4b2ab3bfb",
          balance: "10000000000000000000"  // owner
        },
        {
          privateKey: "0x45822b6c35547aae3d0bedcb9f950a5d7820a37283732f38f083cd07fa3e4cca",
          balance: "5000000000000000000" // 初始余额（单位：Wei，此处为 10000 ETH）
        },
        {
          privateKey: "0x9ed0ad0205a4ea18407364009503735524de548ac3516c31ed1811830a5a46ae",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x371452c7580b28ad95fdd58b98df89b376d42d8271ae06a2e40a99f6b79ae4a6",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x9dfa7baa97fb58b590862685749f8d305d5fc8b5f3b60620a1e77cd94f9d63e6",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x509979618b4200b3d2e5aa6154789ed4941f53d581828163f03dedce2f4c19ac",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x1118f46ecaabc15b220d7934cc504019d43e84d493d9dd0b81451f202770c837",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x57cfdff2ea18eb6a49e2c6d9258f6c8c8fbf2a9dd58d4094c44ba24e462bc9ec",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x0e83d827d4837cbef506c83f9da980c55b530fa2a2bb52832015a13162272519",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x5898735698f8fc253d76af0e9baf6afa465631fe86fd3e9e4a0b2d580dbdb717",
          balance: "5000000000000000000"
        },
        {
          privateKey: "0x8a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d3c877",
          balance: "5000000000000000000"
        },
        {
          privateKey: '0x9c051fdef735f0ab7915ce75032f1594b835cc5352c0364467a63737765374d0',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x4b7ea09eebbfff9394d13e53adfe4de7bad4247a9d33db922b88975b1fc1462b',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x814c2c19a5b268d57987e60c60b3aa7ae6eaa1751f849bc6cf4ea66564e58017',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xd3028aca5ddd8ac4633a84b8ae4c656da2e005089b19226ceaa02d59ed2fb3e9',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xc5caa767ea509284cc918decf3091920dacd50f6230656f83ff9cbed56431e37',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x9ca475b4d3f9ce07447c883de4ed93d4307b8cf3bc70f7f6a4d511574f8e6b81',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xcd21550bcc53ea515a730669a2e6b63626447682ebf3a858664002295f618a5f',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xcc72d567edfb270c842e819f9aa2f51e0ff78e316d8ca9861b896b03bf27afc1',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x9defef5b8c96f97d0b4bea3befa7dc253bb7704537272dcd8246484b1e5eaa62',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xa75fbd87907fc7332fd88a29796adc6edc4aa16a4d4007911caa191dc7c707b4',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xd4c64f1a071f9edc81e057326ab814341d5d85796854984b485fbbdcfe72126c',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x971e54a783eea021db7a40021b7acece53dd135de10afa6b53f18c9b29df00f5',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xe338495521a8bf4d5a722ea01cad2bb16adb23ac28da76edbcc9e2a0b426e0e6',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x3a66ef0980156c7d48353d5cf02b243968b9bbd76452864f855545dd337bbb2d',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x8271d0854213b7f402f194c4e0827ae281250d9885b908bb91ae308ef2202c20',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x448706ac83adf07ef968c5694df6f3a74e0824d207c0fedaf2dfd06a2d1a0f40',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x7d5c0cbc87e53731cd840b88791b14063d2eba5e34d99bc7a8a2707caeeeea63',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x5f15b3773b9725ebef76cb8fa4f72cb43d513f6b02b98740ad00da9654ed44a1',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xfe3dd7068e882cb37689196c48c3d37eb6d403ae014236b4a13189d4a2501cb3',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xff0105c19236626c59bcabfd628a340d0cc4283c11bf0b9b994f3542d7e307f0',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x9b34b8401b7ed2f7fe5436629d23a16dfeb3adeec7f89ebbe55077cd673689d0',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x9e73da119ba432d9c5b4be47d95df92ad8d0b0547abc92e0720b003b93bf3653',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x4cc15b3b56153afb7baa1c4f810e28f2891cd22e34b00871a11437e7ac7d2a22',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x499e05256278a9872f4b0badd1fdcc3232d16c73451bdafa8fca07db8308dffd',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x71c1710880bfaf02d4bfb0cb4aa34a6a3f9d240f0abd4b51fc1675472c36c915',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xfbbda92e199f1a25f233918d8d4e41097a35f0504cf51c95e213a203f51558e3',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x68ebc2325e0dc23665aa2b55329157544f9aa6b7e18a6f6d2edcc7e37f316208',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xfb7bac0018f2291749e9db8d5b044c0f0598fce6332e6b8f337c27d1d88dc743',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xb536116c79c1b27829872b52f13a608e13cac63c3002137843d9f3f4cf891b10',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xae7b17e53a8e098313ff9ffef60039c2550712daa0f06c6cdf88efdd807a1ea1',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x817d133e4693b37d03c6ebd8e376d845305acb1abef56e7b4d85bf612107e9f0',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x223e8a89abd1cc2676c8cf23ed8c369832cd682045a905e473de1b982e0ce261',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xf3fba4f2246e2381092947ab3b0c6e5f44c8fe8c72d2725ba51f19975cecbbbc',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x973bf2133eb83f3f79598087e324c6d711a7becc003d74337ea7ba334a204576',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xb0d4f43a8e0afb4d5c37e7ae7e914e1d9b2fd39e91adad9e6c2e59329b1d5903',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xe3a266a027de835c1097e54e115949a737b0e97dbd2843d174b8741e6a6c1b55',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xf8beb18beb0d0f837aeab5e06a39532d9062b644f15a30e0c7faeb08fb4e6403',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x3f8f150aa22227e398c139786099eca35a026514d84a9deceb3b55b0f2edc1fd',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xbc226f0287e2af1ba5fb6f3810f2f128e78e2a1fba320c82a4a4a651ab3cc438',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x38fb3d91b3795df01c1e21a2c83fdde396e271fdd01cc708808dde23db3fdccb',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x1367f171fc85002828d2c162f4111069a4558784fd75514cce55fe9fff953283',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xebee8e1897a40ae98f70752688d486f3013c57332b6f30fc747341758a315b96',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x24f800aaeb06dd8b6d42f70f96404b6893d0cf07b8a96e5378a2a269056d9db2',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xefab6fda22cb672c71a6089bfacae922b4b2aa3b3d65a2319d59e0fa86bbc49b',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x1366b85fe220d7c8919b762677725a7b9cf48aa251029fc8c8aee3084c50c20d',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xffeb6a6fe3421b7c3ba04120a822ce601c54b37705633d4f82c6f46bab5df905',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x29d7da28786f6647d5e9579a3ffd3accb8290364fd237e917b9060ab5433452e',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xfec6e1a893d0a6844eaa74d5f65c3af9cd85645b8c965337eecd0ad4e4692dd3',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xe4d340ce99ab9c5a28dd73304bd7d927f4b1deb1566abe97a2ebbb3c827502ed',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xa1e3374cd8ee7d62dc78686c78f53916264d56789aeb4863d700db3af8d53c6e',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x69187fda665e235aacf7077ec28f016065b0693134f98f94424cba8437018910',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x46d55be155b1054ab8b3056a66d6b3c8e56eed833a9a5643807f4351338d0f8b',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xe92c24a9c131fba84a699e06a52abb876b7bf096cf9369b5ddc37c02d0c96718',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xec022e5500f3bd74d50c744842e2b51e3ea88dd62e787f4ef8399bca866e92a4',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x971f375b6581caadc48e5b7d37688147343d66890a5814751d50b14f29703944',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xd0db3fc3bdf9d60f5042b6cdefbe687b066962d56d66a8a4cbda86ccf11f7527',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x8437eb9fcc31f364d74230db41d35f1924e2495649e5381419707c3f5d3a3917',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x000ac6d53c70d1dd3c032700d8c250c41fa8eabbab2d8c64ddd0fc3e241404f6',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x1d8489000ab520495388d8aabf1b9c5d443e18b70da55be87f2ff1331d91ea0d',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x338b74b060f86d5ef42e7f607615b481e75b8afdbc3cd1e961c45b9b62eb5308',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xf48209dd25d14022638b02e384e961e5adc001646f1d9f7173581900a84f2796',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x6f78aabb9927334b8b38b031be8758d4d9ab4557382e64cbcf69ef3291a6d872',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x89d38ea6f4319cc995c268b682ddc20e5c366dabd287983471abcf4b74b2ed44',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x8a6aed7b789dec5a65f2211b44a5bae48180be0ea210d0880dc77165aa6df399',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xb4c2438f11487e83608daccdf7fbd8b7d47731f675e7aa30ca9f555e0549bfb5',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xf3934b04b3098ed81934c2c6a475c24d1154d22915170cd7a2574024933ae1a1',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xda7172666580e5e377d547d0b33affa84fcfa5072843165ae013bf693f4acc10',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xcef5ba85c219f97b77bc11a9b34977546984904bdf68ddee929c6c0a48e2968e',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x58356247292d489d383fc034a091f335d8bb49d59633a113012e84cdc7e124cb',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x4bfd933f6231dce64687c62b99712434ba9079f73003c7e3ef69a3f3868456dc',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x1e809b903cec8bf7f9e8116c6c22a76783fddf127e5470abbc43a4cc9f65c843',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x090ff5b9a8d0add2232489ac01e75ef9b7d683a6d1dd5a215b86541b0faac76a',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x0cbd8aa08b7bd80688ad43d4975beb4df3055435e96f867587a7cd8b3bd6c6b5',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x309ed265ada293dbeeb3505f1f4fc370e620a16590b03a1d8c02cdcb88d4ac46',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x2592b8a0a67a1c93dd8a018ef8d2c5dd91d9747bff5abf7c48ce95b079a757c1',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x5196a46ec5b5f40ece1f6060970706239abfc477aa19a9c36f1d31083b3c4f86',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x48cf0f7ac30a30d1b49ffff8cc92de8f4e1327d352bdbd092f3f7167fc59f5ed',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x2aaed1cdf8f4e3175173409e93a247f668320cead6b7c29bd45fe7b51cca3799',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x4258ec46a29d86f6a7e56e80ab02e7c904f64afc7775af42d4eb735b14785a73',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x238079f98eb2f1407070e71391d41944798dad47a5cdf96c5fb0228569748f3b',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x71a0f0dc13d04f0f63370bcaf6085b452ecfc1ea7c8e11f6e3d5a2bdc42de273',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xc4f1031703e668f3de21ba81ebf01fb9c46ed2107b5ac536528522d8db48f639',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x76e503a554af37272357cc1ae6a5434d11abe09bc49e74143632a703b87a2a15',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xc814482686a47c686c080f42d5d63201acef18cd653cf7b189f76a09f1713431',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xc18cd45413d29a49c9301f3bc1ec42b85d456c2713dec6ecfc3489ad64257385',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0xbbe6a17435854092ab700f444947c4e3a42085891198823c847e9ca7d4d1114d',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x5fd081a98686c58566dfd2ff624be1283050a2f10af968379637b95c63703ec6',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x681d19e3d302548500c8eaec56732938eaf47980c3d64f3f172e1b52dc7a9073',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x8452f36434568e093e00b05c31bd77d5f4f0a58c9f76ccd25238f32cca692672',
          balance: '5000000000000000000'
        },
        {
          privateKey: '0x2fbd1668a62fa1ee122d23aae9dbadbc0d66d1a6fb37751d67aac87657164bb0',
          balance: '5000000000000000000'
        }
      ]
    }
  }
};

module starknet_addr::trusted_setup {
    // This is the trusted setup for the KZG commitment. It is not generated from the Aptos core
    // but is loaded from an external source. The logic of the trusted setup is referenced from the following repo:
    // https://github.com/sota-zk-labs/zkp-implementation/tree/main/kzg

    use aptos_std::bls12381_algebra::{FormatG1Compr, FormatG2Compr, G1, G2};
    use aptos_std::crypto_algebra::{deserialize, Element};

    // This G1 point vector has a size of 128.
    // TODO: Increase the G1 point vector size to 4096 and make it compile.
    const G1_SETUP: vector<vector<u8>> = vector[
        x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
        x"9314bf54faa5c75a37adb3e7b8fba5a1db7eb3bfaf6713036aeef072f32dec101e79f1d922d038bf966956ae9c3951c8",
        x"a80c482e39d3eca42340cf4416f1671df948af0da95da665a0edb73274c275054084aa7e241990b576412b9e90e5825a",
        x"ab1936d2a49de92ade17537ce4979da19aff5e5b60ee4eb5d7fba36ace4b28f99a864d1418c6cb24f45f29745e4844a4",
        x"8b11265fdc36f9898d30e704ee824c06821db9116b3629f07440e8b516d1f7cdbef38f7608fc1817b62b9ac46f0faf6b",
        x"a5007952058f41b7730a334d7027ef73c67e8b7e9d38840b16174c69d487fdc93d7b848baec7190c9f8578e03aa72bc2",
        x"89dd3a45f966c2248d07c4b73b0b270c0564cb322eb339f036c0955302dd54d06f4eb4cb30308511dff7d3888c6630e9",
        x"85a5952c1f70067f1dd18a91ca0563803ac67549061058a0f0c8439ae96d90021450198a6809d62b3d54b60fa1238387",
        x"84d0955dbd3c2bb44d34c7f3ee1af98017546b4ec4c60eb23e2e83fa6cec02729dac6cb29fe988126d42c1879586d453",
        x"95a0f67f38eead4f056d22392b6f366316560bf64e36afd7fdbfedb8db73e98642df866e4c7efb9a74d8684a75ba34b1",
        x"829916bb95de197e13fb8509a3990f27a6d678e2035880597ee3c03a6a0f1cdc0e291ffebf7fd04d07d61ce514245d22",
        x"86f90278515ab5fecda3cb42f6a714dfbae1c842ea59e809abd28ddcd7ba4a2001d39f0f6b273014b3c19e858be9d93f",
        x"aea6f13a05dc49290360d018f83ca75fa5c87c8d4fc102a757be69ed018a356d2a0f9a2f9a8cafe14b415f54c122de49",
        x"a576cdd578622c5c52f77f1539ddbfbaaf83a2519a4fcdf1247a46c83cc0443c753307f4f21d1d712e7cae7f6601fd00",
        x"b23d417bdef242fc759d1f3b7a7d7d69cfff22cd578da4fbcb94ef4df2d01ac53874abb412159438a06c1f87ffdad437",
        x"a690be93a0d806379a723816dd36f824fd9e02d7f6cff0373519359e12477363499926dffd532d89f2ed0fc2f093452e",
        x"8f4fb390ecf43fe7523a961114fcc111e345998fb2b3dd2d5d590efe106e051bcdf41f096e9b0f211c5188877fa06472",
        x"837f6d63b787fb757542a75420502fbbdac01056a319b0a11abe727584817c729419e8a0e418e4524eec3b18417f02bc",
        x"800a9dc4e0480a4577d7b9b796632d36699df18346a44180d41591b6f329206b77e4d21944db409b0e33059d174a19d1",
        x"b1a1075229e49bfde016f7923a63e2611e1b8741c860a0d014a378cf74d225e215abf1f67be844705fdbb02690b47a77",
        x"a5a3be013fd3224f470fdaa8c849449416d6b516ca044c456c56efd7265fcaed0ccf824fc5d61f959ad3deadff028137",
        x"a8bbf359dcd7671c959a235876e3e83d1e2039abc1f4954c7a859fcdc8b9cb75268b2762029787114dbeebcdec64920a",
        x"879e1d4efb70c4b77b154813db4acceec8bfc8cc36a999fd151802b7661ef842a58883dbfc1ab3e0d30fa6c72d72516e",
        x"8d6282bce4945edcd9b783c18badbf53c5b106244abdc01a89017ae59416e9979054d34fea1562998a43562d7b5211cf",
        x"864e2e9b16675846e55f70d39cba0226281d1881d6df260bbfce4651b34c2716b71db58a81d48dac9dd1c2e3ef0014cb",
        x"abbfcbb6f157bcc2fa2fe2397c39f99c3e638c371ce48c96c2409c6509242cdbaeb8655898aa84bfaaf59b1f747154c2",
        x"8b6dcb8e2c16c30aba9179bfc66cb1e468166c3491660bab8328f714e7676a8479efe7ea432929b6943476daae2deccf",
        x"96ac18a3619a50432bf1510b3d66d43f6e0c796eba000679854cdaf1ce70299c2a629a6f5853740f5db8dd46ccc38d41",
        x"88b9c199c3d0b8b8b1ef1704380670d44de90aad18902c8d03e7f47a0266a1e82529880d14c14b85b4d03ca0746098b0",
        x"92ed9e3359f36df355d1047fd5b8373c71b94ff119d1846fb31f4ceaeb3877c7df69ae29bcce1c6323fddea4e6018a1b",
        x"953430ff0bfb49994ea619d435cdbf9b35d43ccd0ee0e83380689ac2ecca5e401140936b93fe4ec98776ac9d647b53bd",
        x"8aae38389348202047694b9938946a2a24ef2e31981780b607cfef5b4ab982f56f9447edb565818441b4d17c3f47772e",
        x"b0e98440b887a6a8a6b082c68a2811b8eca35f878f5919ba3a379ee16bd142beb9179434c6440322cb5f069e113d7589",
        x"b52295504b74dfe1a01328cbc1abed36909b1fc92b1428f76078de3fc5f231ea64834a6107d295f1ceba17d356a3e0b4",
        x"95f44701df56cbfe58c49641e78fecf105077a61a8305121087b4d13518830d5ce5438b415bc99b4e35d526f02dc1e5e",
        x"8854714273fb7d63367fad131f4055e70d4f1793e74af00a9a5bac051ae2be15d7be1d7c792536f2f4a17ac4cfb2fecc",
        x"b1704564530df48091097ccde611565093a39693b9ab3bb9b867250c1679e91937c923ebb0177e567f17320fe1071e3c",
        x"9833e05e2dc61dbbcf2b3030d77ad4973217e7dc8505e1cc4205a287700fb1d165de19cbb478d71ff1006e7489788e6b",
        x"aa0624f0a81b95fe1793449d0eedb134b567569414f2b7524e8f246e1ab363714aff1e5493fa28da0f1ee5a221172b97",
        x"80096d903d394de6ed5ec0ab3977acd75546fa0b449fd1760fb98e8b1a2d708f76afac38127892f5da3de2f52754df39",
        x"968fee16486a789dcbe5f8b5d7168967767ffe9bb8abb4cf8d7ea2619021f5fd519c43c4c4043b3d3b66344bfc68eca3",
        x"a4c67fc3171e684031a37c7ca11d4584500fc648d493b9e416dd2401d68c43ba439852b2bf9bc3da205482560772027a",
        x"8bc41482156161f58a25b62df71aff5de983694b606bd9961aaea0f5392f7ab7fb32d0f62d3dd6ef05510216a2817ea5",
        x"ae9697786297ec5a2cb13e69246b2aead66857123c79ec9fa942b45a35ac2a079a6aa3026907bc3d81ad25b289d6c661",
        x"ac26c251411510f7452ea3602f7feb67e2697da966846a7ffb92c042378afdcf6a5938147eed33ae8c6979c789125e8e",
        x"ad2a3dc1c628e171774cc110d39d617c3c13413294887ac2152213ba738fd503cb8cc7f3c1c274d9deabfce02b761040",
        x"a9b3e72088571ef08d91a2945756283765729e268fd7ea2c7cccd1fb73a6e811429d4cfcf42427a2f8910fbcb1479230",
        x"81b278ebfb71a5125fd178bb2c6a280dbd0f61ea5b2d5165cc226616258efa1c201a114c4173da8fb9b9618062ac0842",
        x"87d5b8f05988c46441f8fff763f46d88108128011926ad055470dec86f1fee9c99625dc51031e4faeda58487068b793b",
        x"a409bb499b2c7d8980ea092d605c1ff269a637ade53b1d5ea5501ce05f61a5a4ca6912e03ce1dead60ef62e44c4536e2",
        x"8fe54605004516af8ec6b07d4e2859b449704e0795aa2b1add72aa8e2a051379b36433b1bc725062d9b1549ae55e8828",
        x"a265d1cba4a727e1cebeba300c08c651b0f65b6071e268b55ae97fdeae02393f520f9d7836429535838f3371ff746b15",
        x"a96e05ced77cdba0d24ed5c723dc86e1bfd2b53e6046d69f1ab59ec9ad063fd2867fa0ece25d7e7112dc055b718f9d63",
        x"8e1264175b6b263aa9866cc425d33f85eb4c2cafec92a5047cb6aee2b467f340a7b7a5044e076c4b1cc5091c18e2075b",
        x"92fafe3dcc6ac80c8e4d4b99d20227066475ede86890bac9649872364cf841533de0cce7943b82be17cb771a504be242",
        x"a1ae5b1b9e728c7db2b0b41bd28f845f5509685cebfb43709de8b67078477cdb72d86a5b2bf9656d574df5c672320350",
        x"828e4951700d8d35ffdfaf2a48836a06c2f019399003f65f2894eec80be983de8d63a116d8c01e7e981159d15b891882",
        x"b8c748e5e75076598c585a2d14fcb34ee53d9e95d07354cc8e0c88caaca5c38fba89bec3863cfcd9b70d936f5360720d",
        x"9952162b1fcac14668deeb46aa94f1be2fd93ff3ac7167bad5717108a1bb1b2bbd64363cd4c649de50f15e1e9647a9d3",
        x"b28fc9f0b1b73a14477765949c51eafbf3bb00882b714a2d4b5b0c3f6178ee5056d95255a1e25f4a4dc7a6ac3b1b53f3",
        x"96df08cdb6ba798de49639a6c384096df7570fd427ee1a07a9886dbc5c9dc18133b23a85e9a1f448de34f10bbb7a7805",
        x"88075bf055f13a36bd8820ce634fab01768ac9b1208f81f6a5407302ce2e530052d83dda48cbe25d24107b1626f1d8da",
        x"9980d964061b9809a82d87a9f64a66173c40fa4ee9ed7868e19fadf9721337c1ec04f2b0900441bc7979b9870c33c30e",
        x"8593ade3ad0ab033b5c26397804dd8be3f374d744511bfb156840374374160e072f07c7d3b96aef9bb474e8fcc4d5736",
        x"a458bcf678f4df05e165490210199947adbdf18c743bd1ea5b0b555d084411f0dfa37cc36a5b0e57c03b1050f6c4dedb",
        x"8c511f3d8c1a484d798b23e93376c6d3dfff2e30e63ddeb0223a6dd5c60773fb16a3c8faf02477667a815dd5d41518a3",
        x"9576d954ab7475e72d91659dc5a6cef2210c1fd4bcd6f989ebcd8f52305ffa58bd59dc1ab16794168d801e4e6831cbd3",
        x"b22b20cb8492a982a94317f5d2b8204d21168b74c5f33a00f06e39d76a9d8c3a0064546e6d4023f5625606a632e37d78",
        x"91787614e122e5b402f3e8907965f6cd17aef01179c8df0f86bc50bb2bb3752906d0c52023024a84ac78a002d24d5d59",
        x"828683cd4ca6012432d4e338fbf5deea1f67bffd2a500767e491099e61a0924bb24f366738d64522339d71ef8307d58b",
        x"92401a439da5d4048935e1805873ecb796fbb50ac2a92f59d6cb986bc98e538871ce23c0a2125dd5c4989a0df5a4ffaa",
        x"8fbeaaeb764ed92ec730a36a24c6e8397cdc2e721e6dcf747d5a142a09880bc32ce8920a76dbf95c079aff51eed64f02",
        x"929ea9a03d8e901a3cfdf647f2a37a7ddd935c2b42cab8313d96d8631166fc1c02c110c7f7fb7b7bffb72ba32bb764cc",
        x"8258bee05c25ccb9a9325aa774c8331f44c2d10e55aaa00943debc6625a41d7b2e963863ba796d0b5179fc52458f4b84",
        x"ab54bce9075fd230101610213a9885c20a079b209ee107f49aeca4836087043c0229cf81102fcc81696ee00a097e37f6",
        x"8f79787a03d1742a9fb23be26b118fd922ca679f80a8d805a1267f1fd35ed66390f5ae528755b2a9c02e71b927325e60",
        x"8a9afa7e4453407c1a1967944a272249b60d37e593d593f0f01ab620eb9667fa69abd820974f6b8fc96266955fb9db3e",
        x"92e0866f49e274998f8c1192e38efb6239afd1c044a76c0c3d298bf61745a63813c8f5d1c57e094e4aee633a599773fa",
        x"aa16213bb4463788563310c4ca42e9abe59a132cb11f6867fda82fbdf249b803d7bcce0cd92053db7bb2686cb8f0b598",
        x"939a7cca74e0417a39eed0483f961fa20ecab67c52f4a24f6499aaf7e83140a3eea968409820c5087744d61f9531eb44",
        x"aa5e5cf47a31bfbcae5ad2149b7ec1efa6d08b0d0a83e5b2ecdfdcc24069992484631d86fd334900d2875e598a820a08",
        x"8c1506c0ad4e39ab2458bcb60107ec7d2da485f0eba0708cd25048ea950304c5d0df18a34c56c3debcc8da62f3592b01",
        x"acbc2b58c6cb3b2b5407de688b19f520b0df10c4febcf0dedcb62faa9e1b4fb41592001c5c4be82e46b7833f52727b05",
        x"95dc783ffe087edc8f86574b476094238bf4d99e98742124882428ebf41167c408d6228b7751c998bcf6314ecbc443d1",
        x"b202b5db06252d3554e52de5808af2e5deed128c09ad5bce0b5a0e835dbd7c72849c52c4e7ed1117df0f31d46aa54c1b",
        x"a2c37733c6de99ea9bf2cc15679dd4788baad8f5c7f26062531a8757bf66b9065b2aafa2f637688c7aada521997b28d4",
        x"b1845b5817cff882a7c997fc372001060e6da462d89e4462a74c4cc953ab6658e297fd3f4efd3c2754c4980e9e3bf21a",
        x"8e44c3b0588b52347620438dfa261224be72236491c8ae7f4bdfb0918f6843bed77a07f93263a9884efacec7409616ec",
        x"98a01f6cbcc94f90a66c1d037ff79672fc1c00d30a6dedece76e9796da9798e804be789f5786c1b045572ad05953d549",
        x"833e5e33f62110c78b6280c5bf64aca3f2d50d565a0c77c5c6f52da2ccaac34d06cfaa2ed57aec963f2c6752689a1fa4",
        x"af69ecb677624f7e69486db5528e0c4e379a479cde44cd43a7c6e9fe3ddaf3ad94be8cb15d7cebe69a15c89752556041",
        x"b728818988ccfe89bb6601921531ea2400894df9e64b1b4c2df3ecfbe1baaf241d380c1fd96a8166e352b0895051d51e",
        x"abb0305cbd09e42781e46d8604e2650de88290fc4f7fecccbf3cbb50bf055a654ac17a966733c7ddf236ab1b55d42d84",
        x"8b40211d777515fc09dfc204a9193d26d830dec98f8fac4feac4fbb76dbe3d072b9ba49d6d784faf723f6bf2ec649917",
        x"88360b1792344b6a5c28ed3e597756121b3dfb2003ccc96b6a464c9fbd34f8d590c5ebc70e197ba9f98e5619cf1dc877",
        x"b538eec3477fe9dae94af62e22e20c821e8330e309adb06d175acc5b7ad635347d79af3284ad536534ccc4401f60af8c",
        x"8b1dda9594c0cc1cb192db40b95787216060fba564416a7637789d379900fa3403766081d388f9d05db9aae7407210a6",
        x"95ed35f3f822a57f2457bb76eb6fc1d01da84c87ade3c999642c8b60d891973d9c4468b2ab40d688b174cfd1f04f2baa",
        x"b7c9f4f67d9d6c89ff9f41aa627f91b90b212b2b31b184829476cdbe052a3bcac1762ede32c8c407dfe6357da0235069",
        x"a3b752dbd37b7b286d198e8e1d05801ebea822459c31003367ae84648dbc15b19950ad0235faf992ef95833f0b1b795b",
        x"822c1deb5c7da71a2ffa3479b7f6a4625aee95d09c24b5f268000c0d2967d0591a0c8d6fa2fca5e7d7aabd7ab46a103d",
        x"8092a67b39048a5713e6708ea5c4b0e0eb71930ca68849cd5c54e0f8eba5d1e066911b2d7da73fdfb67a0f9b9d40da49",
        x"803f2bec676d092d40900be15b8e54b2924019063a60715f39d688b67f95e39f3799678ee84975bb2230a064ca43acae",
        x"80cb8fb7093dd30ceca5ab42f529c58072dff633387d02203e97654687f47fb8ed397a841c07cd6d12ede240e5eb2c04",
        x"a3b147c30c2ff1446cebeb231fe3ad1f8ad881541deecbbd4d12dbfc0d4e3f990590c63f0c28ca9132c64ffba8208f45",
        x"8c5328976ecd7dfe6734273410ec083ce927b5949be2ab9b38d87d5739987eed48b33c358d5ef159ab7cb01008d8a76d",
        x"a0de3b80e83aa87cf636e9731ac4f522c3ddaff302e6b8f77c17e530851048a9f1fd381be60c4af45e09478d5e83c964",
        x"96d3de821c5bdcbd9a28f8bbb9d63570079d96e59672a8294db83fa16abf701ad3bd2070db831b85a62038f041b638d7",
        x"93351bcf29dd0e75b6821d410c2febd8f9e0f852a2c2b97e93270ed4aec2e3021ce28445ef97a202fa3337dbf7c46f0f",
        x"ad178a998984a8177f11e28cf2f8af5e5ba1450268f36bb51c65105b1bbe368de480251b7f5ff7f9168658ae061bad56",
        x"825261cfa558c55d9e90747bc18445bb76ae02e2378ead1ab6cbda8419506906652627d260d31fe4092fd7da503817d3",
        x"81f0669034769871bb13dcd734ab867a220c5cb64c8a8cec0c7f25f6d143c5b3bb14680c874bdb0af04f436629642c1b",
        x"b82f7ce163c735a262063101299d37ceb87b43a5dea6fed3c09801a14972ca278a77d74ca084cae130438b747eee96d9",
        x"94a396cc853a127f2aa325f30f380ecb140c4be2e23791053077087b5707b3c5fd584727d04fd7dd7ad154d0da4c90bf",
        x"abd0d2403c7266a168f4ff34712428cd6a8278134c8be61428e1afd60754ee527af9c7bcca8c6b236317cda81eae0ee8",
        x"944e0922597be0dd5937d382ba746a015c6bf2326052853d4b95d9d1153684c56484f62622e1d447e51e1205c63f4f70",
        x"851b6c4a1f9cf751c87d7b2223d66a8d2713f0776d6b8a3fa83b363cf343c769067bb9b2984f1718ddd7a852d48dc27d",
        x"866ed9614c38b9e6ad6ccc3ebc3c4a180183d4bd3427dbb54af94811cfa25eccd0de587f3e06ab9d29e35b03e67beb21",
        x"a9390cecd3df56e0227cb5c787e7816b045d31d575a493a21c14bb25e1e70d31c0464d7584047c88945046203c9f02a3",
        x"a2a8f9dde696fa3ca0e4f02af2eebd2b6e727cb9981bf108ed3449748b91170f4a003f995fe3edd947d31edfeeebe0d0",
        x"b9fcb77f327efc687fcd88b8e6b841bdb705eabde6638830b6716c0a4db96b8ddc201695964faa57b33993e1272b6239",
        x"afcbf0f2f33c4769bad3d91bdb1529c6cfc4741045ad9d8a10a018a7c85cefb1a0f43ecb43fa681a8ddb04d2c8aac1f6",
        x"8737aaabb74ec74d535b256eabfdfdfa72ea267a7a10b90601a07a4923c87d34881a08c7f3db40b3bd215057beaf2bbb",
        x"824c2d61942313c72a3556104adcd856169bffd2afea7833ba385410eded1ac2ed6cb02befd48f713e16c546b7cae2e8",
        x"b5efac31921a1662590250ab0cfb3ab03f005977766e8b155237bfbbfffd74a6a818f53a9dd4747c59882ac33e76d860",
        x"994b201c89c55859a0540961cc89c5e046edd67898503d4f3931b48b86a12e56381c8285632c4451a0cd40615728954a",
        x"83322bba7cac5dafad6c56d136d16dfcbc71d60d39857530c62d7ae8d7a8b829a400d9ca00d94f77679964f906d45206",
        x"98a2c98c39b220b760bb725fb3436acdaf41cc991b15b6da302ca65584648bca290b5c7642bee5c67d749322f5b91853",
    ];
    const G2_SETUP: vector<u8> = x"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8";
    const G2S_SETUP: vector<u8> = x"96d6dc5ff3492dbaf76bd8338cc714f775d5a847b28e1c6bba152a47a2404bca076e2269a66fe5019926e948ac12e32e037b7484094298cb698d035565e9c9205a5c9172c69f62a9c95a2a1aebf643307357bcb7535033d731819d79c55fc423";
    const G1_GENERATOR: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

    public fun get_g2s(): Element<G2> {
        std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2S_SETUP))
    }

    public fun get_g2(): Element<G2> {
        std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2_SETUP))
    }

    public fun get_g1_generator(): Element<G1> {
        std::option::extract(&mut deserialize<G1, FormatG1Compr>(&G1_GENERATOR))
    }
}
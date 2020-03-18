unit uRomUtil;

interface

type
  TRomUtil = class
    private
      procedure EnumProcess();      //�г�ϵͳ����
      procedure FindProcessMem();   //���ҽ����ڴ�
      procedure SelectProcess();    //ѡ�����
      procedure FirstFind(dwValue: LongInt);        //��һ�β���
      procedure NextFind(dwValue: LongInt);         //��һ�β���
      procedure AmendMem();  //�޸��ڴ�
      procedure ReStart();  //����
      procedure CompareAPage(dwBase: Pointer;regionSize: Cardinal;dwValue: LongInt);//�Ƚ��ڴ�ҳ
    protected

    public
      FirstFindFlag : Boolean;  //�Ƿ�Ϊ��һ�β���
      ListCnt : Integer; //��Ч��ַ����
      AddressList : array of string;  //��ַ�б�
      processHandle : THandle; //��ǰ���̾��
      FProcessEntry32 : array[0..100] of TProcessEntry32;  //���н��̽ṹ����
      constructor Create; override;
      destructor Destroy; override;
    end;

implementation

end.

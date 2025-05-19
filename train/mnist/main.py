import torch
import os
from torch import nn  # neural network
from torch import optim  # 优化器
from torch.utils.data import DataLoader  # 数据加载器

import torchvision
from torchvision import datasets  # 数据集
from torchvision import transforms  # 数据正前期

DatasetDir = os.environ.get("DATASETDIR", "./dataset")


# 自定义神经网络模型类，需要继承自torch.nn.Module
class MyMnistNet(nn.Module):

    def __init__(self, class_num):
        """
        :param class_num: 分类任务的类别数目
        """
        super().__init__()
        # 采用torchvision库中已有的alexnet模型
        self.net = torchvision.models.alexnet(
            # 使用PyTorch附带的预训练参数
            pretrained=True,
            # dropout防止过拟合
            dropout=0.3,
        )
        # 修改AlexNet模型的分类器，主要修改分类数量
        self.net.classifier = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(256 * 6 * 6, 4096),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.3),
            nn.Linear(4096, 4096),
            nn.ReLU(inplace=True),
            nn.Linear(4096, class_num),
        )

    # 定义模型的前向传播函数
    def forward(self, inputs):
        """
        :param inputs: 模型的输入
        :return: 模型的输出
        """
        outputs = self.net(inputs)
        return outputs


# 得到模型实例
mymnistnet = MyMnistNet(10)

# 数据增强 & 数据集 & 数据加载器
transform = transforms.Compose(
    [
        # 修改图片尺寸
        transforms.Resize((96, 96)),
        # 将单通道的MNIST图片升为三通道
        transforms.Grayscale(num_output_channels=3),
        # 转换为张量
        transforms.ToTensor(),
        # 对数据进行归一化，有利于提升模型拟合能力
        transforms.Normalize(
            (
                0.2,
                0.2,
                0.2,
            ),
            (
                0.3,
                0.3,
                0.3,
            ),
        ),
    ]
)
train_set = datasets.MNIST(
    root=DatasetDir, train=True, download=True, transform=transform
)
test_set = datasets.MNIST(
    root=DatasetDir, train=False, download=True, transform=transform
)

train_loader = DataLoader(
    dataset=train_set, batch_size=512, shuffle=True, drop_last=False
)
test_loader = DataLoader(
    dataset=test_set, batch_size=512, shuffle=True, drop_last=False
)

# loss函数
criterion = nn.CrossEntropyLoss()

# 优化器，传入模型的参数与学习率
optimizer = optim.AdamW(params=mymnistnet.parameters(), lr=0.0001)


# 模型训练
def train_model(
    data_loader: DataLoader,
    model: nn.Module,
    param_optimizer: optim.Optimizer,
    loss_criterion: nn.Module,
    device_: torch.device,
    epoch,
    print_freq,
):
    """
    :param print_freq: 打印频率
    :param epoch: 训练轮次
    :param data_loader: 训练数据集
    :param model: 待训练模型
    :param param_optimizer: 模型优化器
    :param loss_criterion: 计算loss的评判器
    :param device_: 使用的计算设备
    :return: 平均loss，平均acc
    """
    # 模型进入训练模式，会有计算图生成与梯度计算
    model.train()
    # 将模型迁移到设备上(CPU or GPU)
    model.to(device_)
    total_loss = 0.0
    total_acc = 0.0
    batch_num = len(data_loader)
    # 遍历数据加载器，数据加载器可以看作是Mini-Bath的集合
    for idx, (img, target) in enumerate(data_loader, start=1):
        # 将数据也迁移到与模型相同的设备上(CPU or GPU)
        img = img.to(device_)
        target = target.to(device_)
        # 计算训练集loss
        outputs = model(img)
        loss = loss_criterion(outputs, target)
        # 优化器梯度清零
        param_optimizer.zero_grad()
        # 反向传播，得到参数的梯度
        loss.backward()
        # 梯度下降
        param_optimizer.step()
        # 计算训练集准确率
        predict = outputs.max(dim=-1)[-1]
        acc = predict.eq(target).float().mean()

        current_loss = loss.cpu().item()
        current_acc = acc.cpu().item()
        total_loss += current_loss
        total_acc += current_acc
        if idx % print_freq == 0:
            print(
                f"Epoch:{epoch:03d}  Batch num:[{idx:03d}/{batch_num:03d}]    Loss:{current_loss:.4f}    Acc:{current_acc:.4f}"
            )
    return total_loss / batch_num, total_acc / batch_num


# 模型测试
def test_model(
    data_loader: DataLoader,
    model: nn.Module,
    loss_criterion: nn.Module,
    device_: torch.device,
):
    """
    :param data_loader: 测试数据集
    :param model: 待测试模型
    :param loss_criterion: 计算loss的评判器
    :param device_: 使用的计算设备
    :return: 平均loss，平均acc
    """
    # 模型进入评估模式，不会有计算图生成，也不会计算梯度
    model.eval()
    # 将模型迁移到设备上(CPU or GPU)
    model.to(device_)
    total_loss = 0.0
    total_acc = 0.0
    batch_num = len(data_loader)
    # 遍历数据加载器
    for idx, (img, target) in enumerate(data_loader, start=1):
        # 将数据也迁移到与模型相同的设备上(CPU or GPU)
        img = img.to(device_)
        target = target.to(device_)
        # 计算测试集loss
        with torch.no_grad():
            outputs = model(img)
            loss = loss_criterion(outputs, target)
        # 计算测试集准确率
        predict = outputs.max(dim=-1)[-1]
        acc = predict.eq(target).float().mean()

        current_loss = loss.cpu().item()
        current_acc = acc.cpu().item()
        total_loss += current_loss
        total_acc += current_acc
    return total_loss / batch_num, total_acc / batch_num


# 检测是否有可用的CUDA设备
device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

# 将模型移动到设备上
mymnistnet.to(device)
print("Using device:", device, ", cuda count:", torch.cuda.device_count())
# 如果有多个 GPU 可用，则使用 DataParallel 包装模型
if torch.cuda.device_count() > 1:
    mymnistnet = nn.DataParallel(mymnistnet)

# 训练5轮
for i in range(5):
    train_model(train_loader, mymnistnet, optimizer, criterion, device, i + 1, 16)
    test_loss, test_acc = test_model(test_loader, mymnistnet, criterion, device)
    print(f"Epoch:{i + 1:03d}  Test-Loss:{test_loss:.4f}    Test-Acc:{test_acc:.4f}")

# 保存模型参数
torch.save(mymnistnet.state_dict(), "mymnistnet_weight.pth")

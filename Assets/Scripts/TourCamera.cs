using UnityEngine;

public class TourCamera : MonoBehaviour
{
    // 在场景中游览的相机（不要给相机加碰撞器！）
    public Transform tourCamera;

    #region 相机移动参数

    public float moveSpeed = 1.0f;
    public float rotateSpeed = 90.0f;
    public float shiftRate = 2.0f; // 按住Shift加速
    public float minDistance = 0.5f; // 相机离不可穿过的表面的最小距离（小于等于0时可穿透任何表面）

    #endregion

    #region 运动速度和其每个方向的速度分量

    private Vector3 direction = Vector3.zero;
    private Vector3 speedForward;
    private Vector3 speedBack;
    private Vector3 speedLeft;
    private Vector3 speedRight;
    private Vector3 speedUp;
    private Vector3 speedDown;

    #endregion

    void Start()
    {
        if (tourCamera == null)
            tourCamera = gameObject.transform;
        // 防止相机边缘穿透
        //if (tourCamera.GetComponent<Camera>().nearClipPlane > minDistance / 3)
        //{
        //    tourCamera.GetComponent<Camera>().nearClipPlane /= 3;
        //}
    }

    void Update()
    {
        GetDirection();

        // 检测是否离不可穿透表面过近
        RaycastHit hit;
        while (Physics.Raycast(tourCamera.position, direction, out hit, minDistance))
        {
            // 消去垂直于不可穿透表面的运动速度分量
            float angel = Vector3.Angle(direction, hit.normal);
            float magnitude = Vector3.Magnitude(direction) * Mathf.Cos(Mathf.Deg2Rad * (180 - angel));
            direction += hit.normal * magnitude;
        }

        tourCamera.Translate(direction * moveSpeed * Time.deltaTime, Space.World);
    }

    private void GetDirection()
    {
        #region 加速移动

        if (Input.GetKeyDown(KeyCode.LeftShift)) moveSpeed *= shiftRate;
        if (Input.GetKeyUp(KeyCode.LeftShift)) moveSpeed /= shiftRate;

        #endregion

        #region 键盘移动

        // 复位
        speedForward = Vector3.zero;
        speedBack = Vector3.zero;
        speedLeft = Vector3.zero;
        speedRight = Vector3.zero;
        speedUp = Vector3.zero;
        speedDown = Vector3.zero;
        // 获取按键输入
        if (Input.GetKey(KeyCode.W)) speedForward = tourCamera.forward;
        if (Input.GetKey(KeyCode.S)) speedBack = -tourCamera.forward;
        if (Input.GetKey(KeyCode.A)) speedLeft = -tourCamera.right;
        if (Input.GetKey(KeyCode.D)) speedRight = tourCamera.right;
        if (Input.GetKey(KeyCode.E)) speedUp = Vector3.up;
        if (Input.GetKey(KeyCode.Q)) speedDown = Vector3.down;
        direction = speedForward + speedBack + speedLeft + speedRight + speedUp + speedDown;

        #endregion

        #region 鼠标旋转

        if (Input.GetMouseButton(1))
        {
            // 转相机朝向
            tourCamera.RotateAround(tourCamera.position, Vector3.up,
                Input.GetAxis("Mouse X") * rotateSpeed * Time.deltaTime);
            tourCamera.RotateAround(tourCamera.position, tourCamera.right,
                -Input.GetAxis("Mouse Y") * rotateSpeed * Time.deltaTime);

            // 转运动速度方向
            direction = V3RotateAround(direction, Vector3.up, Input.GetAxis("Mouse X") * rotateSpeed * Time.deltaTime);
            direction = V3RotateAround(direction, tourCamera.right,
                -Input.GetAxis("Mouse Y") * rotateSpeed * Time.deltaTime);
        }

        #endregion
    }

    /// <summary>
    /// 计算一个Vector3绕旋转中心旋转指定角度后所得到的向量。
    /// </summary>
    /// <param name="source">旋转前的源Vector3</param>
    /// <param name="axis">旋转轴</param>
    /// <param name="angle">旋转角度</param>
    /// <returns>旋转后得到的新Vector3</returns>
    public Vector3 V3RotateAround(Vector3 source, Vector3 axis, float angle)
    {
        Quaternion q = Quaternion.AngleAxis(angle, axis); // 旋转系数
        return q * source; // 返回目标点
    }
}
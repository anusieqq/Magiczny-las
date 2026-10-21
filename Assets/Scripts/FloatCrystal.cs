
using UnityEngine;

public class CrystalFloat : MonoBehaviour
{
    [Header("Floating Animation")]
    [SerializeField] private float amplitude = 0.2f;
    [SerializeField] private float frequency = 0.8f;

    [Header("Optional Rotation")]
    [SerializeField] private bool rotate = true;
    [SerializeField] private float rotationSpeed = 10f;

    private Vector3 startPosition;
    private float randomOffset;

    private void Start()
    {
        startPosition = transform.localPosition;
        randomOffset = Random.Range(0f, Mathf.PI * 2f);
    }

    private void Update()
    {
        float offsetY = Mathf.Sin(
            Time.time * frequency * 2f * Mathf.PI + randomOffset
        ) * amplitude;

        transform.localPosition = startPosition
                                + Vector3.up * offsetY;

        if (rotate)
        {
            transform.Rotate(
                Vector3.up,
                rotationSpeed * Time.deltaTime,
                Space.Self
            );
        }
    }
}
